package safe

import (
	"testing"
)

func TestIsSafeCommand(t *testing.T) {
	tests := []struct {
		command  string
		args     []string
		expected bool
	}{
		{"list", []string{}, true},
		{"status", []string{"my-release"}, true},
		{"install", []string{"my-release"}, false},
		{"upgrade", []string{"my-release"}, false},
		{"show", []string{"values", "my-release"}, true},
		{"repo", []string{"list"}, true},
		{"repo", []string{"add", "stable"}, false},
	}

	for _, tt := range tests {
		result := isSafeCommand(tt.command, tt.args)
		if result != tt.expected {
			t.Errorf("isSafeCommand(%s, %v) = %v; want %v", tt.command, tt.args, result, tt.expected)
		}
	}
}

func TestIsModifyingCommand(t *testing.T) {
	tests := []struct {
		command  string
		args     []string
		expected bool
	}{
		{"install", []string{"my-release"}, true},
		{"upgrade", []string{"my-release"}, true},
		{"list", []string{}, false},
		{"status", []string{"my-release"}, false},
		{"repo", []string{"add", "stable"}, true},
		{"repo", []string{"list"}, false},
	}

	for _, tt := range tests {
		result := isModifyingCommand(tt.command, tt.args)
		if result != tt.expected {
			t.Errorf("isModifyingCommand(%s, %v) = %v; want %v", tt.command, tt.args, result, tt.expected)
		}
	}
}

func TestIsProductionContext(t *testing.T) {
	tests := []struct {
		context  string
		expected bool
	}{
		{"dev-cluster", false},
		{"prod-cluster", true},
		{"production", true},
		{"staging", false},
		{"live-env", true},
		{"test", false},
	}

	for _, tt := range tests {
		result := isProductionContext(tt.context)
		if result != tt.expected {
			t.Errorf("isProductionContext(%s) = %v; want %v", tt.context, result, tt.expected)
		}
	}
}
