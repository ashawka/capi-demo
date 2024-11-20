# Multi rancher kubeconfig helper functions

This document provides guidance on using the helper functions for managing Kubernetes kubeconfig files. These functions facilitate combining, flattening, and updating kubeconfig files.

## Load the functions by sourcing the file

* `source multi-rancher/kubeconfig-helper-functions.sh`

---

## Method descriptions

### `combine_configs`

**Purpose**: Combines multiple kubeconfig files into a single context using the `KUBECONFIG` environment variable.

#### Usage

```bash
combine_configs <config_file_list>
```

- `<config_file_list>`: A colon-separated list of kubeconfig file paths (e.g., `/path/to/config1:/path/to/config2`).

#### Example

```bash
combine_configs "/home/user/config1:/home/user/config2"
```

#### Notes

- If no argument is provided, a warning is displayed, and the merge will fail.

---

### `flatten_to_dot_kube`

**Purpose**: Merges the kubeconfig files specified in the `KUBECONFIG` environment variable and flattens them into `~/.kube/config`.

#### Usage

```bash
flatten_to_dot_kube
```

#### Example

```bash
flatten_to_dot_kube
```

#### Notes
- Requires that `KUBECONFIG` is already set using `combine_configs`.

---

### `flatten_to_file`

**Purpose**: Merges and flattens the kubeconfig files into a specified file or a default location.

#### Usage
```bash
flatten_to_file <output_file>
```

- `<output_file>`: (Optional) Path to the output file. Defaults to `kubeconfig-YYYYMMDD` in the current directory if not provided.

#### Example
```bash
flatten_to_file "/home/user/merged-kubeconfig"
```

#### Notes
- Displays a warning if no argument is provided.

---

### `kubeconfig_replace`

**Purpose**: Replaces the value of a YAML object in a kubeconfig file using the `yq` command.

#### Usage
```bash
kubeconfig_replace <yaml_file> <yaml_object> <new_value>
```

- `<yaml_file>`: Path to the YAML file to be modified.
- `<yaml_object>`: The YAML object to update (e.g., `metadata.name`).
- `<new_value>`: The new value to assign to the specified YAML object.

#### Example
```bash
kubeconfig_replace "/home/user/config.yaml" "metadata.name" "new-cluster-name"
```

#### Notes
- Requires `yq` to be installed.
- Validates the existence of the YAML file and the `yq` command before making changes.
- Displays usage instructions if incorrect parameters are provided.

---
