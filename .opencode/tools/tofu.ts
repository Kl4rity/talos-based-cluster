import { tool } from "@opencode-ai/plugin";

export const plan = tool({
  description: "Run 'tofu plan' in the terraform directory with environment variables from direnv",
  args: {
    target: tool.schema
      .string()
      .optional()
      .describe("Optional target to plan (e.g., 'module.workload_cluster')"),
  },
  async execute(args, context) {
    const targetFlag = args.target ? ` -target=${args.target}` : "";
    const command = `cd terraform && tofu plan -var="hcloud_token=$HCLOUD_TOKEN" -var="letsencrypt_email=$LETSENCRYPT_EMAIL" -var="hetzner_dns_api_token=$HETZNER_DNS_API_TOKEN"${targetFlag}`;

    // Using Bun's shell utility to run the command
    const result = await Bun.$`bash -c ${command}`;
    return result;
  },
});

export const apply = tool({
  description: "Run 'tofu apply' in the terraform directory with environment variables from direnv",
  args: {
    target: tool.schema
      .string()
      .optional()
      .describe("Optional target to apply (e.g., 'module.workload_cluster')"),
    autoApprove: tool.schema
      .boolean()
      .optional()
      .describe("Skip interactive approval prompt (default: false)"),
  },
  async execute(args, context) {
    const targetFlag = args.target ? ` -target=${args.target}` : "";
    const approveFlag = args.autoApprove ? " -auto-approve" : "";
    const command = `cd terraform && tofu apply -var="hcloud_token=$HCLOUD_TOKEN" -var="letsencrypt_email=$LETSENCRYPT_EMAIL" -var="hetzner_dns_api_token=$HETZNER_DNS_API_TOKEN"${targetFlag}${approveFlag}`;

    const result = await Bun.$`bash -c ${command}`;
    return result;
  },
});

export const init = tool({
  description: "Run 'tofu init' in the terraform directory",
  args: {},
  async execute(args, context) {
    const result = await Bun.$`cd terraform && tofu init`;
    return result;
  },
});

export const validate = tool({
  description: "Run 'tofu validate' to validate terraform files",
  args: {},
  async execute(args, context) {
    const result = await Bun.$`cd terraform && tofu validate`;
    return result;
  },
});

export const format = tool({
  description: "Format or check terraform code formatting",
  args: {
    check: tool.schema
      .boolean()
      .optional()
      .describe("Check formatting without modifying files (default: false)"),
  },
  async execute(args, context) {
    const checkFlag = args.check ? " -check" : "";
    const result = await Bun.$`cd terraform && tofu fmt${checkFlag}`;
    return result;
  },
});

export const destroy = tool({
  description: "Run 'tofu destroy' to destroy infrastructure",
  args: {
    autoApprove: tool.schema
      .boolean()
      .optional()
      .describe("Skip interactive approval prompt (default: false)"),
  },
  async execute(args, context) {
    const approveFlag = args.autoApprove ? " -auto-approve" : "";
    const command = `cd terraform && tofu destroy -var="hcloud_token=$HCLOUD_TOKEN" -var="letsencrypt_email=$LETSENCRYPT_EMAIL" -var="hetzner_dns_api_token=$HETZNER_DNS_API_TOKEN"${approveFlag}`;

    const result = await Bun.$`bash -c ${command}`;
    return result;
  },
});
