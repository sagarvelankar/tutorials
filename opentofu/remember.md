- If you are using traditional configuration management like chef, puppet, ansible within your compute instances, you can use OpenTofu to configure bootstrapping software like cloud-init to activate your configuration management software on first system boot. Bootstrapping may be required to configure the configuration management tool with environment specific data which cannot be hardcoded  into the ec2 image. Something like an init container.

- For AWS account, vpc with subnet with only 1 ip address and autoscaling group with one ec2 instance in 1 zone. VPC NACL should not allow any connections from outside. Only connection to git repository server and artifact repository server should be allowed. S3 bucket needs to be created with vpc endpoint and iam access to the ec2 instance iam role. dynamodb table locking is required since we cannot guarantee that only one ec2 will be running terraform for this account at one time. Maybe ASG starts EC2 instance in another az.

- For managing cloudflare (CDN), dnsimple (DNS), Github (git), how can terraform be run ? It should be run from the respective cloud for each service or from the corresponding aws account like network-nonprod and network-prod, devops-nonprod and devops-prod ?

- Should GitOps run terraform plan ( refresh current state and create plan of what changes need to be done ) and wait for someone to review the plan or just apply the plan ? If it waits for approval, then if someone makes manual changes, it will need to wait for approval before removing the manual change which could be a risk. There is no plan stage for argocd kubernetes yaml or ansible playbook so only for terraform we will have plan in GitOps.

- blocks
  - variable
    - description
    - type
    - default
    - validation
      - condition
      - error_message
  - locals
  - terraform
    - required_version
    - required_providers
    - backend
      - s3
      - azurerm
      - gcs
  - provider
    - alias
  - resource
    - provider
    - count
    - for_each
    - depends_on
    - lifecycle
      - precondition
        - condition
          - each
          - count
        - error_message
      - postcondition
        - condition
          - self
          - each
          - count
        - error_message
    - connection
    - provisioner
      - file
      - local-exec
      - remote-exec
    - dynamic
      - for_each
      - content
      - iterator
      - labels
      - dynamic
  - data
    - provider
    - count
    - for_each
    - depends_on
    - lifecycle
    - connection
    - provisioner
      - file
      - local-exec
      - remote-exec
  - module
    - providers
    - count
    - for_each
    - depends_on
  - output
    - description
    - sensitive
    - depends_on
    - precondition
      - condition
      - error_message
    - value
  - check
    - data
    - assert
      - condition
      - error_message

- expression operators

- built-in functions

- Upgrades
  - When upgrading kubernetes version, argocd version, fluxcd version, tofu controller version, ansible version, liquibase version, opentofu/terraform version, module version, provider version, need to follow an upgrade path which involves testing if the upgrade makes any changes to the existing infrastructure. Ideally, it should not. But still important to test for all infrastructure for all components before upgrading in production.

  - Do not use experimental features in production modules.

  - While upgrading, if we get deprecation warnings, then need to change the code.

  - The supported ways for external software to interact with OpenTofu are via the JSON output modes offered by some commands and via exit status codes. We may extend certain JSON formats with new object properties but we will not remove or make breaking changes to the definitions of existing properties. Natural language command output or log output is not a stable interface and may change in any new version. If you write software that parses this output then it may need to be updated when you upgrade OpenTofu. If you need access to data that is not currently available via one of the machine-readable JSON interfaces, we suggest opening a feature request to discuss your use-case.

  - Steps
    - Prepare a disaster recovery plan
    - Back up your state file and code
    - Run plan and check if any changes are being made
    - Before you begin using OpenTofu for larger changes, test out tofu apply with a smaller, non-critical change.
    - Test the rollback also with small change if rollback is done.

    - You can minimize the risk of being affected by missed regressions in final releases by proactively testing modules against alpha, beta, and release candidate packages. We recommend doing so only in isolated development or staging environments rather than against your production infrastructure. If you find a change in behavior in a prerelease build that seems contrary to the promises in this document, please open an issue in OpenTofu's GitHub repository to discuss it.

- https://github.com/virtualroot/awesome-opentofu/blob/main/README.md

- Buy jfrog artifactory and use it as terraform registry for providers. https://jfrog.com/help/r/jfrog-artifactory-documentation/terraform-registry. For modules, their code needs to be checked into the GitOps repository. Sonatype nexus does not seem to have this type of registry. Can raw repository type of sonatype nexus be used for terraform registry for providers ? Chatgpt says it is possible. Terraform expects providers to follow a specific structure, so organize the raw repository as /v1/providers/<namespace>/<type>/<version>/<os>/<arch>. For Terraform to recognize the registry, you may need a providers.json file in the root of your raw repository, outlining available providers, versions, and URLs for each OS and architecture.

- Just like docker images are in central devops jfrog artifactory or sonatype nexus and are referenced in kubernetes yamls, similarly vm images and terraform providers should be in the central devops jfrog artifactory or sonatype nexus and not in some S3 buckets.

- Should ec2 instance running k3s be able to make any changes to itself, or its vpc, subnet, s3 state bucket, dynamodb table, etc. ? If yes, then that is security risk. If no, then how will changes to these resources be made ?

- Debugging = TF_LOG=JSON

- Attributes as blocks mode
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#removing-all-ingress-and-egress-rules
  - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group#ingress

- Check blocks allow you to define custom conditions that execute on every OpenTofu plan or apply operation without affecting the overall status of an operation. Check blocks execute as the last step of a plan or apply after OpenTofu has planned or provisioned your infrastructure. We recommend using check blocks to validate the status of infrastructure as a whole. We only recommend using postconditions when you want a guarantee on a single resource based on that resource's configuration.

- Data sources allow OpenTofu to use information defined outside of OpenTofu, defined by another separate OpenTofu configuration, or modified by functions.

- Use data sources with tags to get resources that we need to use as inputs for other resources instead of reading from parent state file or storing in AWS systems manager parameter store.

- Use depends_on if does not contain managed resource attribute.

- As data sources are essentially a read only subset of resources, they also support the same meta-arguments of resources with the exception of the lifecycle configuration block.

- Use provider block default region and another with alias and different region and use provider meta argument in resource and data block to create the resource or get resource information from a different region. Can be used inside module blocks also so that all resource and data inside the module block use the different region provider. Do this to create EKS cluster in 2 regions with aws_eks module.

- Experiment with the behavior of OpenTofu's expressions from the OpenTofu expression console, by running the tofu console command. It uses terraform configuration in current directory and state file for evaluation.

- Expressions : Values of arguments
  
- ```condition ? true_val : false_val```
  - Recommended to have both values of the same type
  
- Input variable validation

- precondition vs postconditions
  - Use preconditions and postconditions for resource to check if the input arguments are valid and if after resource is applied, the calculated values are valid. Use precondition for output to check if the output value can be set.
  - We recommend using preconditions for assumptions, so that future maintainers can find them close to the other expressions that rely on that condition. This lets them understand more about what that resource is intended to allow.
  - We recommend using postconditions for guarantees, so that future maintainers can find them close to the resource configuration that is responsible for implementing those guarantees. This lets them more easily determine which behaviors they should preserve when changing the configuration.
  - Which resource or output value would be most helpful to report in the error message? OpenTofu will always report errors in the location where the condition was declared.
  - Which approach is more convenient? If a particular resource has many dependencies that all make an assumption about that resource, it can be pragmatic to declare that once as a post-condition of the resource, rather than declaring it many times as preconditions on each of the dependencies.
  - Is it helpful to declare the same or similar conditions as both preconditions and postconditions? This can be useful if the postcondition is in a different module than the precondition because it lets the modules verify one another as they evolve independently.
  - During the apply phase, a failed precondition will prevent OpenTofu from implementing planned actions for the associated resource. 
  - However, a failed postcondition will halt processing after OpenTofu has already implemented these actions. The failed postcondition prevents any further downstream actions that rely on the resource, but does not undo the actions OpenTofu has already taken.

- Example conditions
  - ```condition = var.name != "" && lower(var.name) == var.name```
  - ```condition = contains(["STAGE", "PROD"], var.environment)```
  - ```condition = length(var.items) != 0```
  - ```condition = alltrue([for v in var.instances : contains(["t2.micro", "m3.medium"], v.type)])```
  - ```condition = can(regex("^[a-z]+$", var.name))```
  - ```condition = can(tostring(data.terraform_remote_state.example.outputs["name"]))```
  - ```condition = can(tolist(data.terraform_remote_state.example.outputs["items"]))```
  - ```condition = can(var.example.foo)```
  - ```condition = can(var.example[0])```

- For
  - Create a tuple/list/set of values from set, map, etc.
    - ```[for s in var.list : upper(s)]```
    - ```[for k, v in var.map : length(k) + length(v)]```
    - ```[for i, v in var.list : "${i} is ${v}"]```
  - Create object/map from set, map, etc.
    - ```{for s in var.list : s => upper(s)}```
  - filtering
    - ```[for s in var.list : upper(s) if s != ""]```
  - unordered sets
    - ```toset([for e in var.set : e.example])```
  - grouping
    - ```for name, user in var.users : user.role => name...```

- functions
  - expand
    - ```min([55, 2453, 2]...)```

- Dont use == []. Instead use length function.  var.list == [] may seem like it would return true if var.list were an empty list, but [] actually builds a value of type tuple([]) and so the two values can never match. In this situation it's often clearer to write length(var.list) == 0 instead.

- Named values
  - ```<RESOURCE TYPE>.<NAME>```
  - ```var.<NAME>```
  - ```local.<NAME>```
  - ```module.<MODULE NAME>.<OUTPUT NAME>```
  - ```data.<DATA TYPE>.<NAME>```
  - ```path.module```
  - ```path.root```
  - ```terraform.workspace```
  - ```count.index```
  - ```each.key```
  - ```each.value```
  - ```self```

- If you are writing a shared module which needs a prefix to help create unique names, define an input variable for your module and allow the calling module to define the prefix. The calling module can then use terraform.workspace to define it if appropriate, or some other value if not.

- splat expressions
  - ```[for o in var.list : o.interfaces[0].name]```
  - ```var.list[*].interfaces[0].name```
  - Use in dynamic block```for_each = var.a[*]```. If var.a is set, then var.a[*] is a list with 1 element which is var.a so one dynamic block. If var.a is null, then no blocks.


