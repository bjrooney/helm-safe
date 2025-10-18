package safe

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"slices"
	"sort"
	"strings"

	"github.com/fatih/color"
	"github.com/spf13/pflag"
)

// Solarized color scheme
var (
	solarizedRed    = color.New(color.FgHiRed).Add(color.Bold)
	solarizedOrange = color.New(color.FgHiYellow).Add(color.Bold)
	solarizedYellow = color.New(color.FgYellow)
	solarizedGreen  = color.New(color.FgGreen)
	solarizedCyan   = color.New(color.FgCyan)
	solarizedBlue   = color.New(color.FgBlue)
	solarizedViolet = color.New(color.FgMagenta)
)

// Version will be set at build time
var Version = "dev"

// ModifyingCommandMap defines commands that are modifying by themselves or with specific subcommands.
var ModifyingCommandMap = map[string][]string{
	"install": {}, "upgrade": {}, "uninstall": {}, "delete": {}, "rollback": {},
	"create": {}, "dependency": {"update", "build"}, "package": {},
	"plugin": {"install", "update", "uninstall"},
	"repo":   {"add", "update", "remove"},
	"push":   {},
}

// SafeCommandMap defines commands that are safe and should pass through without checks
var SafeCommandMap = map[string][]string{
	"list": {}, "ls": {}, "status": {}, "get": {}, "history": {},
	"show":       {"values", "chart", "readme", "all"},
	"test":       {},
	"lint":       {},
	"verify":     {},
	"version":    {},
	"help":       {},
	"search":     {"hub", "repo"},
	"pull":       {},
	"template":   {},
	"dependency": {"list"},
	"plugin":     {"list"},
	"repo":       {"list", "index"},
	"completion": {"bash", "zsh", "fish", "powershell"},
	"env":        {},
}

// MessageType defines the category of the message to be printed.
type MessageType int

const (
	TypeNotice MessageType = iota
	TypeWarning
	TypeAlert
	TypeProductionAlert
)

// printMessage provides a uniform, styled format for user-facing messages.
func printMessage(msgType MessageType, title string, message string, hint string) {
	switch msgType {
	case TypeNotice:
		solarizedOrange.Print("❗ NOTICE: ")
		solarizedOrange.Printf("%s\n", title)
		if message != "" {
			fmt.Printf("          %s\n", message)
		}
	case TypeWarning:
		solarizedYellow.Print("✋ WARNING: ")
		solarizedOrange.Printf("%s\n", title)
		if message != "" {
			solarizedBlue.Print("         -> ")
			fmt.Println(message)
		}
	case TypeAlert:
		solarizedOrange.Printf("⚠️  %s ⚠️\n", title)
	case TypeProductionAlert:
		solarizedRed.Printf("🚨 %s 🚨\n", title)
	}

	if hint != "" {
		solarizedYellow.Printf("   %s\n", hint)
	}
}

// printColoredList prints a list of items with alternating Solarized colors
func printColoredList(items []string) {
	colors := []*color.Color{solarizedCyan, solarizedGreen, solarizedYellow, solarizedViolet, solarizedBlue}
	for i, item := range items {
		if i > 0 {
			fmt.Print(", ")
		}
		colors[i%len(colors)].Print(item)
	}
	fmt.Println()
}

// Execute is the main entry point for the plugin.
func Execute() error {
	args := os.Args[1:]

	if len(args) == 0 {
		printMessage(TypeNotice, "No command specified", "Use 'helm safe --help' for usage information", "")
		return nil
	}

	// Handle help flags
	if args[0] == "--help" || args[0] == "-h" {
		showHelp()
		return nil
	}

	// Handle version flag
	if args[0] == "--version" || args[0] == "-V" {
		fmt.Printf("helm-safe version %s\n", Version)
		return nil
	}

	command := args[0]
	remainingArgs := args[1:]

	// Check if this is a safe command that should pass through
	if isSafeCommand(command, remainingArgs) {
		return executeHelm(args)
	}

	// Check if this is a modifying command that needs safety checks
	if !isModifyingCommand(command, remainingArgs) {
		return executeHelm(args)
	}

	// Perform safety checks for modifying commands
	if err := performSafetyChecks(args); err != nil {
		return err
	}

	// Show confirmation prompt
	if !confirmExecution(args) {
		printMessage(TypeNotice, "Operation cancelled", "", "")
		return nil
	}

	return executeHelm(args)
}

// isSafeCommand checks if the command is safe and should pass through without checks
func isSafeCommand(command string, args []string) bool {
	subcommands, exists := SafeCommandMap[command]
	if !exists {
		return false
	}

	// If no subcommands specified, the command itself is safe
	if len(subcommands) == 0 {
		return true
	}

	// Check if the subcommand is in the safe list
	if len(args) > 0 {
		return slices.Contains(subcommands, args[0])
	}

	return false
}

// isModifyingCommand checks if the command is modifying and needs safety checks
func isModifyingCommand(command string, args []string) bool {
	subcommands, exists := ModifyingCommandMap[command]
	if !exists {
		return false
	}

	// If no subcommands specified, the command itself is modifying
	if len(subcommands) == 0 {
		return true
	}

	// Check if the subcommand is in the modifying list
	if len(args) > 0 {
		return slices.Contains(subcommands, args[0])
	}

	return false
}

// performSafetyChecks validates namespace and context requirements
func performSafetyChecks(args []string) error {
	flags := pflag.NewFlagSet("helm-safe", pflag.ContinueOnError)
	flags.ParseErrorsWhitelist.UnknownFlags = true

	var namespace string
	var kubeContext string

	flags.StringVarP(&namespace, "namespace", "n", "", "Kubernetes namespace")
	flags.StringVar(&kubeContext, "kube-context", "", "Kubernetes context")

	if err := flags.Parse(args); err != nil {
		// Ignore parsing errors for unknown flags
	}

	// Check for required flags
	var missingFlags []string

	if namespace == "" && os.Getenv("HELM_NAMESPACE") == "" {
		missingFlags = append(missingFlags, "--namespace/-n")
	}

	if kubeContext == "" && os.Getenv("HELM_KUBECONTEXT") == "" {
		missingFlags = append(missingFlags, "--kube-context")
	}

	if len(missingFlags) > 0 {
		printMessage(TypeWarning, "Missing required safety flags", "", "")
		fmt.Print("Missing flags: ")
		printColoredList(missingFlags)
		fmt.Println()
		printMessage(TypeNotice, "Safety requirement",
			"Modifying Helm commands must specify both namespace and context to prevent accidental operations",
			"Add the missing flags and try again")
		return fmt.Errorf("missing required safety flags: %s", strings.Join(missingFlags, ", "))
	}

	// Validate context exists
	if kubeContext != "" {
		if err := validateContext(kubeContext); err != nil {
			return err
		}
	}

	return nil
}

// validateContext checks if the specified context exists in kubeconfig
func validateContext(context string) error {
	cmd := exec.Command("kubectl", "config", "get-contexts", "-o", "name")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to get kubectl contexts: %v", err)
	}

	contexts := strings.Split(strings.TrimSpace(string(output)), "\n")
	for _, ctx := range contexts {
		if strings.TrimSpace(ctx) == context {
			return nil
		}
	}

	printMessage(TypeWarning, "Invalid context specified",
		fmt.Sprintf("Context '%s' does not exist in your kubeconfig", context), "")

	fmt.Println("Available contexts:")
	sort.Strings(contexts)
	printColoredList(contexts)

	return fmt.Errorf("context '%s' not found", context)
}

// confirmExecution shows a confirmation prompt for the operation
func confirmExecution(args []string) bool {
	namespace := getEffectiveNamespace(args)
	context := getEffectiveContext(args)

	fmt.Println()
	solarizedOrange.Println("🔍 HELM OPERATION CONFIRMATION")
	fmt.Println("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

	solarizedBlue.Print("Command:   ")
	fmt.Printf("helm %s\n", strings.Join(args, " "))

	solarizedBlue.Print("Context:   ")
	solarizedCyan.Println(context)

	solarizedBlue.Print("Namespace: ")
	solarizedCyan.Println(namespace)

	fmt.Println()

	// Check if this is a production-like context
	if isProductionContext(context) {
		printMessage(TypeProductionAlert, "PRODUCTION CONTEXT DETECTED",
			"You are about to execute a command in what appears to be a production context", "")
		fmt.Println()
	}

	solarizedYellow.Print("Do you want to continue? (y/N): ")

	reader := bufio.NewReader(os.Stdin)
	response, err := reader.ReadString('\n')
	if err != nil {
		return false
	}

	response = strings.TrimSpace(strings.ToLower(response))
	return response == "y" || response == "yes"
}

// getEffectiveNamespace returns the namespace that will be used
func getEffectiveNamespace(args []string) string {
	flags := pflag.NewFlagSet("helm-safe", pflag.ContinueOnError)
	flags.ParseErrorsWhitelist.UnknownFlags = true

	var namespace string
	flags.StringVarP(&namespace, "namespace", "n", "", "Kubernetes namespace")
	flags.Parse(args)

	if namespace != "" {
		return namespace
	}

	if envNs := os.Getenv("HELM_NAMESPACE"); envNs != "" {
		return envNs
	}

	return "default"
}

// getEffectiveContext returns the context that will be used
func getEffectiveContext(args []string) string {
	flags := pflag.NewFlagSet("helm-safe", pflag.ContinueOnError)
	flags.ParseErrorsWhitelist.UnknownFlags = true

	var kubeContext string
	flags.StringVar(&kubeContext, "kube-context", "", "Kubernetes context")
	flags.Parse(args)

	if kubeContext != "" {
		return kubeContext
	}

	if envCtx := os.Getenv("HELM_KUBECONTEXT"); envCtx != "" {
		return envCtx
	}

	// Get current context from kubectl
	cmd := exec.Command("kubectl", "config", "current-context")
	output, err := cmd.Output()
	if err != nil {
		return "unknown"
	}

	return strings.TrimSpace(string(output))
}

// isProductionContext checks if the context name suggests it's production
func isProductionContext(context string) bool {
	lowerContext := strings.ToLower(context)
	prodKeywords := []string{"prod", "production", "live", "prd"}

	for _, keyword := range prodKeywords {
		if strings.Contains(lowerContext, keyword) {
			return true
		}
	}

	return false
}

// executeHelm executes the helm command with the provided arguments
func executeHelm(args []string) error {
	helmBin := os.Getenv("HELM_BIN")
	if helmBin == "" {
		helmBin = "helm"
	}

	cmd := exec.Command(helmBin, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

// showHelp displays the help information
func showHelp() {
	fmt.Printf("helm-safe version %s\n\n", Version)
	fmt.Println("DESCRIPTION:")
	fmt.Println("  helm-safe provides an interactive safety net for modifying Helm commands.")
	fmt.Println("  It acts as a wrapper around destructive Helm operations to prevent common")
	fmt.Println("  mistakes by requiring explicit --namespace and --kube-context flags.")
	fmt.Println()
	fmt.Println("USAGE:")
	fmt.Println("  helm safe [HELM_COMMAND] [ARGS...]")
	fmt.Println()
	fmt.Println("EXAMPLES:")
	fmt.Println("  helm safe install my-app ./chart --namespace my-ns --kube-context dev")
	fmt.Println("  helm safe upgrade my-app ./chart --namespace my-ns --kube-context dev")
	fmt.Println("  helm safe uninstall my-app --namespace my-ns --kube-context dev")
	fmt.Println()
	fmt.Println("MODIFYING COMMANDS (require safety checks):")

	var commands []string
	for cmd, subcmds := range ModifyingCommandMap {
		if len(subcmds) == 0 {
			commands = append(commands, cmd)
		} else {
			for _, subcmd := range subcmds {
				commands = append(commands, fmt.Sprintf("%s %s", cmd, subcmd))
			}
		}
	}
	sort.Strings(commands)

	for i, cmd := range commands {
		if i%4 == 0 {
			fmt.Print("  ")
		}
		fmt.Printf("%-18s", cmd)
		if (i+1)%4 == 0 || i == len(commands)-1 {
			fmt.Println()
		}
	}

	fmt.Println()
	fmt.Println("SAFE COMMANDS (pass through without checks):")
	fmt.Println("  list, status, get, history, show, test, lint, verify, version, help")
	fmt.Println("  search, pull, template, completion, env")
	fmt.Println()
}
