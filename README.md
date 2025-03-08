# **cvcli: A Better Way to Copy-Paste in the Command Line**

> **Project in Development**

Clipboard management tools like **`Ditto`** or the built-in **Windows Clipboard** (accessible via `Windows + V`) are widely used in GUI environments. However, in the command line, there is a lack of such convenient clipboard tools. When it comes to persisting clipboard data in the terminal, the process often involves complex and manual operations.

`cvcli` solves this problem by providing a **lightweight, command-line clipboard manager** with **key-value pair storage**. It is implemented in **Lua** and compiled into executables for **Windows** and **Linux** using `luastatic`.

---

## **Installation**

> In the future, `cvcli` may support installation via package managers like `winget`, `yum`, or `apt`. For now, the installation process is manual.

### **Using Installation Scripts**

`cvcli` provides installation scripts for a one-click setup:

- **Windows**:  
  - Download the project to your local machine and run the `install.bat` file located in the `install` directory.
  - By default, `cvcli` will be installed in the `C:\Program Files\cvcli` directory.
  - To change the default installation path, modify the target directory in the `install.bat` file.

- **Linux**:  
  - Open a terminal and run the following command:
    ```bash
    sudo bash install/install.sh
    ```
  - By default, `cvcli` will be installed in `/usr/local/bin/` and can be accessed globally via the `cvcli` command.

### **Manual Installation**

- **Windows**:  
  - Move the downloaded `cvcli.exe` file to the `C:\Program Files\cvcli\` directory.
  - Add this directory to the system's `PATH` environment variable (if it’s not already added).

- **Linux**:  
  - Move the downloaded `cvcli` file to `/usr/local/bin/`:
    ```bash
    sudo mv cvcli /usr/local/bin/
    ```
  - Ensure the file is executable:
    ```bash
    sudo chmod +x /usr/local/bin/cvcli
    ```

---

## **Getting Started**

`cvcli` stores data using key-value pairs in a `cvcli.yml` file located in the program's root directory.  
If installed correctly, open your terminal and run `cvcli`. You should see the following output:

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
key(s): 0
lastkey: ---EMPTY--- 
```

### **Output Breakdown**:
- **Version**: `0.1`  
- **Environment**: `Windows`  
- **Stored Keys**: `0`  
- **Last Used Key**: `---EMPTY---`  

If the `cvcli.yml` file is missing or corrupted, `cvcli` will prompt you to rebuild it:

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
---YML ERR---
Input 'rebuild' to rebuild (WARN: all data will lost)>>>
```

Enter `rebuild` to recreate the `cvcli.yml` file. Upon success, you will see the following message:

```cmd
---REBUILD SUCCESS---
```

---

## **Commands**

### **Write**

To store data in `cvcli`, use the following syntax:

```bash
cvcli -w [k] [v]
```

- `[k]`: The key name.
- `[v]`: The value.

#### **Key Naming Rules**

Keys in `cvcli` must follow these rules:
1. **Keys cannot start with `---`** (reserved for `cvcli`).
2. **Keys cannot contain special characters**, such as spaces.
3. **Reserved keywords cannot be used as keys**, such as:
   - `-w`, `-wv`, `-wl`, `-wvl`, `-wr`, `-wvlr`, `-l`, `-mk`, `-mv`, `-cc`, `-cr`.
4. **Keys must be unique**: Adding a duplicate key will overwrite the previous value.

#### **Examples**

- **Standard Write**:
    ```bash
    cvcli -w hello "hello world!"
    ```
    This stores the value `"hello world!"` under the key `hello`.

- **Write Clipboard Content to a Key**:
    ```bash
    cvcli -wv [k]
    ```
    Example:
    ```bash
    cvcli -wv p
    ```
    This stores the current clipboard content under the key `p`.

### **Read**

- **Read a Specific Key**:
    ```bash
    cvcli [k]
    ```
    Example:
    ```bash
    cvcli hello
    ```
    This retrieves the value associated with the key `hello` and copies it to the system clipboard.

- **Read the Last Used Key**:
    ```bash
    cvcli -l
    ```

    This retrieves the value of the last accessed key and copies it to the clipboard.

### **Delete**

`cvcli` allows you to delete specific keys:

```bash
cvcli [k]
```

Example:
```bash
cvcli hello
```
This deletes the key `hello` and its associated value.

---

### **Combine or Replace Files**

`cvcli` supports importing data from external `.yml` files.

1. **Combine Files**:
    ```bash
    cvcli -cc [filename]
    ```
    Combines the contents of `filename.yml` with the current storage. Keys in the imported file overwrite duplicate keys in the existing data.

2. **Replace Files**:
    ```bash
    cvcli -cr [filename]
    ```
    Replaces the current storage with the contents of `filename.yml`.

---

## **Errors and Troubleshooting**

Here are some common errors you might encounter:

1. **YML File Missing**:
    ```cmd
    >>>ERR 1<<< LOSS OF YML FILES
    [CAUSE] The `cvcli.yml` file is missing.
    [HINT] Use `cvcli -cr [filename]` to replace it or run `cvcli` to rebuild.
    ```

2. **YML Formatting Error**:
    ```cmd
    >>>ERR 2<<< YML FORMATTING ERROR
    [CAUSE] The `cvcli.yml` file contains invalid formatting.
    [HINT] Manually check the file or replace it with a valid one.
    ```

3. **Clipboard Read Failure**:
    ```cmd
    >>>ERR 4<<< CLIPBOARD READ FAILURE
    [CAUSE] Unable to read clipboard content.
    [HINT] Ensure your system clipboard service is functioning correctly.
    ```

4. **Key Not Found**:
    ```cmd
    >>>ERR 6<<< KEY NOT FOUND
    [CAUSE] The specified key does not exist.
    [HINT] Use an existing key or create a new one first.
    ```

5. **Invalid Key Name**:
    ```cmd
    >>>ERR 11<<< INVALID KEY NAME
    [CAUSE] The provided key name is invalid.
    [HINT] Ensure the key follows the naming rules.
    ```

6. **Merge Conflict**:
    ```cmd
    >>>ERR 9<<< MERGE CONFLICT
    [CAUSE] Conflicting keys were found during a file merge.
    [HINT] Manually resolve the conflicts or use the replace option.
    ```

7. **Permission Denied**:
    ```cmd
    >>>ERR 14<<< INSUFFICIENT PERMISSIONS
    [CAUSE] The user lacks permission to access or modify the file/clipboard.
    [HINT] Ensure you have the necessary permissions (e.g., administrator privileges).
    ```

---

For more information or contributions, visit the [GitHub repository](https://github.com/Water-Run/cvcli).  
