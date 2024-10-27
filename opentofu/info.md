## Usage

```
tofu [global options] <command> <subcommand> [args]
```

## Global options 

use these before the subcommand, if any

- ```-chdir=DIR``` 
Switch to a different working directory before executing the given subcommand.
```
mkdir -p dev && tofu -chdir=`pwd`/dev version && rm -rf dev
OpenTofu v1.8.3
on darwin_arm64
```

- ```-help```       
Show help output, or the help for a specified subcommand.
```
tofu workspace new -help
Usage: tofu [global options] workspace new [OPTIONS] NAME

  Create a new OpenTofu workspace.

Options:

    -lock=false         Don't hold a state lock during the operation. This is
                        dangerous if others might concurrently run commands
                        against the same workspace.

    -lock-timeout=0s    Duration to retry a state lock.

    -state=path         Copy an existing state file into the new workspace.


    -var 'foo=bar'      Set a value for one of the input variables in the root
                        module of the configuration. Use this option more than
                        once to set more than one variable.

    -var-file=filename  Load variable values from the given file, in addition
                        to the default files terraform.tfvars and *.auto.tfvars.
                        Use this option more than once to include more than one
                        variables file.
```
- ```-version``` 
An alias for the "version" subcommand.

## Backend configuration

https://opentofu.org/docs/language/settings/backends/configuration/

A backend defines where OpenTofu stores its state data files.

Most non-trivial OpenTofu configurations either integrate with TACOS (TF Automation and Collaboration Software) or use a backend to store state remotely.

## Command: init

https://opentofu.org/docs/cli/commands/init/

Initialize a new or existing OpenTofu working directory by creating initial files, loading any remote state, downloading modules, etc.

This is the first command that should be run for any new or existing OpenTofu configuration per machine. This sets up all the local data necessary to run OpenTofu that is typically not committed to version control.

This command is always safe to run multiple times. Though subsequent runs may give errors, this command will never delete your configuration or state. Even so, if you have important information, please back it up prior to running this command, just in case.

The tofu init command initializes a working directory containing OpenTofu configuration files. This is the first command that should be run after writing a new OpenTofu configuration or cloning an existing one from version control. It is safe to run this command multiple times.

This command performs several different initialization steps in order to prepare the current working directory for use with OpenTofu.

This command is always safe to run multiple times, to bring the working directory up to date with changes in the configuration. Though subsequent runs may give errors, this command will never delete your existing configuration or state.

### Root variables value assignments

This command requires value assignment for variables used in module sources and backend configuration blocks.

- -var 'foo=bar'          

Set a value for one of the input variables in the root module of the configuration. Use this option more than once to set more than one variable.

Sets a value for a single input variable declared in the root module of the configuration. Use this option multiple times to set more than one variable. 

- -var-file=filename      

Load variable values from the given file, in addition to the default files terraform.tfvars and *.auto.tfvars. Use this option more than once to include more than one variables file.

Sets values for potentially many input variables declared in the root module of the configuration, using definitions from a "tfvars" file. Use this option multiple times to include values from more than one file.

### Backend Initialization

During init, the root configuration directory is consulted for backend configuration and the chosen backend is initialized using the given configuration settings.

- -reconfigure            

Reconfigure a backend, ignoring any saved configuration.

Re-running init with an already-initialized backend will update the working directory to use the new backend settings.

The -reconfigure option disregards any existing configuration, preventing migration of any existing state.

- -migrate-state          

Reconfigure a backend, and attempt to migrate any existing state.

Re-running init with an already-initialized backend will update the working directory to use the new backend settings.

The -migrate-state option will attempt to copy existing state to the new backend, and depending on what changed, may result in interactive prompts to confirm migration of workspace states. The -force-copy option suppresses these prompts and answers "yes" to the migration questions. Enabling -force-copy also automatically enables the -migrate-state option.

- -force-copy             

Suppress prompts about copying state data when initializating a new state backend. This is equivalent to providing a "yes" to all confirmation prompts.

- -backend=false          

Disable backend or cloud backend initialization for this configuration and use what was previously initialized instead.

To skip backend configuration, use -backend=false. Note that some other init steps require an initialized backend, so it is recommended to use this flag only when the working directory was already previously initialized for a particular backend.

aliases: -cloud=false

- -backend-config=path    

Configuration to be merged with what is in the configuration file's 'backend' block. This can be either a path to an HCL file with key/value assignments (same format as terraform.tfvars) or a 'key=value' format, and can be specified multiple times. The backend type must be in the configuration itself.

The -backend-config=... option can be used for partial backend configuration, in situations where the backend settings are dynamic or sensitive and so cannot be statically specified in the configuration file.

### Copy a source module

- -from-module=SOURCE     

Do not use. For routine use it is recommended to check out configuration from version control separately, using the version control system's own commands.

Copy the contents of the given module into the target directory before initialization.

Given a version control source, it can serve as a shorthand for checking out a configuration from version control and then initializing the working directory for it.

If the source refers to an example configuration, it can be copied into a local directory to be used as a basis for a new configuration.

### Child Module Installation

During init, the configuration is searched for module blocks, and the source code for referenced modules is retrieved from the locations given in their source arguments.

- -get=false              

Disable downloading modules for this configuration.

To skip child module installation, use -get=false. Note that some other init steps can complete only when the module tree is complete, so it's recommended to use this flag only when the working directory was already previously initialized with its child modules.

- -upgrade                

Install the latest module and provider versions allowed within configured constraints, overriding the default behavior of selecting exactly the version recorded in the dependency lockfile.

Re-running init with modules already installed will install the sources for any modules that were added to configuration since the last init, but will not change any already-installed modules. Use -upgrade to override this behavior, updating all modules to the latest available source code.

### Plugin Installation

After successful installation, OpenTofu writes information about the selected providers to the dependency lock file. You should commit this file to your version control system to ensure that when you run tofu init again in future OpenTofu will select exactly the same provider versions. 

- -upgrade                

Install the latest module and provider versions allowed within configured constraints, overriding the default behavior of selecting exactly the version recorded in the dependency lockfile.

Upgrade all previously-selected plugins to the newest version that complies with the configuration's version constraints. This will cause OpenTofu to ignore any selections recorded in the dependency lock file, and to take the newest available version matching the configured version constraints.

- -plugin-dir             

Directory containing plugin binaries. This overrides all default search paths for plugins, and prevents the automatic installation of plugins. This flag can be used multiple times.

Force plugin installation to read plugins only from the specified directory, as if it had been configured as a filesystem_mirror in the CLI configuration. If you intend to routinely use a particular filesystem mirror then we recommend configuring OpenTofu's installation methods globally. You can use -plugin-dir as a one-time override for exceptional situations, such as if you are testing a local build of a provider plugin you are currently developing.

- -lockfile=MODE          

Set a dependency lockfile mode. Currently only "readonly" is valid.

suppress the lockfile changes, but verify checksums against the information already recorded. It conflicts with the -upgrade flag. If you update the lockfile with third-party dependency management tools, it would be useful to control when it changes explicitly.

### Others

- -lock=false             

Don't hold a state lock during backend migration. This is dangerous if others might concurrently run commands against the same workspace.

Disable locking of state files during state-related operations.

- -lock-timeout=0s        

Duration to retry a state lock.

Override the time OpenTofu will wait to acquire a state lock. The default is 0s (zero seconds), which causes immediate failure if the lock is already held by another process.

- -ignore-remote-version  

A rare option used for cloud backend and the remote backend only. Set this to ignore checking that the local and remote OpenTofu versions use compatible state representations, making an operation proceed even when there is a potential mismatch. See the documentation on configuring OpenTofu with cloud backend for more information.

- -test-directory=path    

Set the OpenTofu test directory, defaults to "tests". When set, the test command will search for test files in the current directory and in the one specified by the flag.

- -input=false            

Disable interactive prompts. Note that some actions may require interactive prompts and will error if input is disabled.

Ask for input if necessary. If false, will error if input was required.

- -no-color               

If specified, output won't contain any color.

- -json

Produce output in a machine-readable JSON format, suitable for use in text editor integrations and other automated systems. Always disables color.

validate      Check whether the configuration is valid
plan          Show changes required by the current configuration
apply         Create or update infrastructure
destroy       Destroy previously-created infrastructure

console       Try OpenTofu expressions at an interactive command prompt
fmt           Reformat your configuration in the standard style
force-unlock  Release a stuck lock on the current workspace
get           Install or upgrade remote OpenTofu modules
graph         Generate a Graphviz graph of the steps in an operation
import        Associate existing infrastructure with a OpenTofu resource
login         Obtain and save credentials for a remote host
logout        Remove locally-stored credentials for a remote host
metadata      Metadata related commands
output        Show output values from your root module
providers     Show the providers required for this configuration
refresh       Update the state to match remote systems
show          Show the current state or a saved plan
state         Advanced state management
taint         Mark a resource instance as not fully functional
test          Execute integration tests for OpenTofu modules
untaint       Remove the 'tainted' state from a resource instance

## version       

Displays the version of OpenTofu and all installed plugins

Options:
- -json       Output the version information as a JSON object.

Examples:

- With no options
```
tofu version      
OpenTofu v1.8.3
on darwin_arm64
```

- With -json option
```
tofu version -json
{
  "terraform_version": "1.8.3",
  "platform": "darwin_arm64",
  "provider_selections": {}
}
```

workspace     Workspace management
