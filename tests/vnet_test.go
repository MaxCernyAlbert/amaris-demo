//go:build terratest
package tests

import (
	"testing"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVnetModulePlan(t *testing.T) {
	t.Parallel()
	opts := &terraform.Options{ TerraformDir: "../envs/dev", NoColor: true }
	out := terraform.InitAndPlanAndShowWithStruct(t, opts)
	assert.NotNil(t, out)
}
