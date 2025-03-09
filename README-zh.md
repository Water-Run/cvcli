# cvcli: 更好的在命令行中复制粘贴  

> 项目开发中  

在GUI页面，有很多不错的剪贴板升级工具：如`Ditto`，以及更常用的：通过`Windows + V`键唤醒的Windows剪贴板。  
然而，在命令行界面中，却缺乏类似方便剪贴板工具存在：当我们想要持久化我们的剪贴板时，需要比较复杂的操作。  
`cvcli`提供了一个命令行的剪贴板键值对存储工具，由`lua`实现，并通过`luastatic`编译为`Windows`和`Linux`的可执行文件。

---

## 安装  

> `cvcli`未来考虑支持通过`winget`、`yum`和`apt`实现安装；不过，目前`cvcli`只能手动操作安装流程。

### 使用安装脚本  

`cvcli` 提供了安装脚本以实现一键安装的功能。  

- **Windows**:  
  - 将项目下载至本地，运行 `install` 目录下的 `install.bat`。
  - 默认情况下，`cvcli` 将安装至 `C:\Program Files\cvcli` 目录。
  - 如果需要更改默认安装路径，请编辑 `install.bat` 中的目标目录配置。

- **Linux**:  
  - 打开终端，运行以下命令：

    ```bash
    sudo bash install/install.sh
    ```

  - 默认情况下，`cvcli` 会安装到 `/usr/local/bin/`，并可以通过全局命令 `cvcli` 调用。  

### 手动安装  

- **Windows**:  
  - 将下载的 `cvcli.exe` 文件移动到 `C:\Program Files\cvcli\` 目录。
  - 将该目录添加到系统环境变量的 `PATH` 中（如果尚未添加）。  

- **Linux**:  
  - 将下载的 `cvcli` 文件移动到 `/usr/local/bin/` 目录：
  
    ```bash
    sudo mv cvcli /usr/local/bin/
    ```

  - 确保文件具有可执行权限：

    ```bash
    sudo chmod +x /usr/local/bin/cvcli
    ```

---

## 快速上手  

`cvcli`通过键值对实现数据存储，存储于程序同目录的`cvcli.yml`中。  
如果你已经按照上述教程正确安装，打开终端，输入`cvcli`，你应该能看到如下内容：  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
key(s): 0
lastkey: ---EMPTY--- 
```  

包含了如下信息：  

- **版本**: 0.1  
- **环境**: Windows  
- **存储的键数**: 0  
- **上一个使用的键**: (无)  

在运行时，`cvcli` 会检查 `cvcli.yml` 是否正常。如果不正常，`cvcli` 将进行对应的提示：  

```cmd
C:\Users\linzh>cvcli  
[cvcli]
ver: 0.1
env: win
---YML ERR---
Input 'rebuild' to rebuild (WARN: all data will lost)>>>
```

输入 `rebuild` 重新构建 `cvcli.yml`。顺利构建后，你应该能看到 `---REBUILD SUCCESS---`。

---

### **指令**

#### **写入**

向 `cvcli` 存入数据的标准语法如下：

```bash
cvcli -w [k] [v]
```

- `[k]` 是键名（Key）。
- `[v]` 是值名（Value）。

##### **键的命名规则**  

在 `cvcli` 中，键名必须遵守以下规则：  

1. **不能以连续的三个 `-` 开头**（这是 `cvcli` 的保留字）。
2. **不能包含特殊字符**，例如空格。  
3. **不能是以下保留字之一：**  
   - `-w`、`-wv`、`-wl`、`-wvl`、`-wr`、`-wvlr`、`-l`、`-mk`、`-mv`、`-cc`、`-cr`。
4. **必须唯一**：每个键在 `cvcli` 中是唯一的，重复键会覆盖之前的值。

#### **写入指令**

##### **标准写入**  

以下示例展示了如何写入键值对：

```bash  
cvcli -w hello "hello world!"
```  

这表示向键 `hello` 写入值 `"hello world!"`。

##### **写入剪贴板中的值**  

将当前剪贴板中待粘贴的内容作为值写入：  

```bash  
cvcli -wv [k]
```  

示例：

```bash
cvcli -wv p
```

这表示向键 `p` 写入当前剪贴板中的值。

##### **限制写入到已存在的键**

- **向已存在的键写入指定值：**

  ```bash
  cvcli -wr [k] [v]
  ```

  示例：

  ```bash
  cvcli -wr hello "updated value"
  ```

  这表示仅当键 `hello` 已存在时，才向其写入值 `"updated value"`。

---

#### **读取**

`cvcli` 提供两种方式读取数据：

1. **读取指定键的值：**

   ```bash
   cvcli [k]
   ```

   例如：

   ```bash
   cvcli hello
   ```

   这表示读取键 `hello` 对应的值。

   **注意：**
   - 读取出的值将自动添加到系统剪贴板，方便直接粘贴使用。

2. **读取上次使用的键：**

   ```bash
   cvcli -l
   ```

   - `-l` 表示 *last*，用于读取上一次使用的键的值。
   - 读取出的值同样会自动复制到系统剪贴板。

---

#### **删除**

`cvcli` 提供删除功能，但仅支持指定键的删除：

```bash
cvcli [k]
```

示例：

```bash
cvcli hello
```

这表示删除键 `hello` 及其对应的值。

---

#### **合并或替换文件**

`cvcli` 提供了将外部 `.yml` 文件与当前存储合并或替换的功能：

1. **合并文件：**

   ```bash
   cvcli -cc [filename]
   ```

   - `-cc` 表示 *copy and combine*，将指定的 `filename.yml` 文件内容与当前存储合并。
   - 如果出现重复键，则使用文件中的值覆盖当前存储的值。

2. **替换文件：**

   ```bash
   cvcli -cr [filename]
   ```

   - `-cr` 表示 *copy and replace*，将指定的 `filename.yml` 文件内容替换当前存储的内容。

---

## 异常信息  

以下是可能的异常信息及其解释：  

1. **YML文件丢失**  

    ```cmd
    >>>ERR 1<<< LOSS OF YML FILES
    [CAUSE] 无法找到 `cvcli.yml` 文件。
    [HINT] 使用 `cvcli -cr [filename]` 替换可用的 YML 文件，或运行 `cvcli` 进行重建。
    ```

2. **YML格式错误**  

    ```cmd
    >>>ERR 2<<< YML FORMATTING ERROR
    [CAUSE] `cvcli.yml` 格式错误。
    [HINT] 手动检查，或使用 `cvcli -cr [filename]` 替换。  
    ```

3. **YML无法访问**  

    ```cmd
    >>>ERR 3<<< YML IS NOT ACCESSIBLE
    [CAUSE] 无法访问 `cvcli.yml` 文件。
    [HINT] 检查文件权限或路径。  
    ```

4. **无法读取剪贴板**  

    ```cmd
    >>>ERR 4<<< CLIPBOARD READ FAILURE
    [CAUSE] 无法读取系统剪贴板内容。
    [HINT] 检查操作系统的剪贴板服务是否正常。  
    ```

5. **无法写入剪贴板**  

    ```cmd
    >>>ERR 5<<< CLIPBOARD WRITE FAILURE
    [CAUSE] 无法将内容写入系统剪贴板。
    [HINT] 检查操作系统的剪贴板服务是否正常。  
    ```

6. **指定键不存在**  

    ```cmd
    >>>ERR 6<<< KEY NOT FOUND
    [CAUSE] 键不存在。
    [HINT] 使用正确的键名或先创建该键。  
    ```

7. **指定文件不存在**  

    ```cmd
    >>>ERR 7<<< FILE NOT FOUND
    [CAUSE] 提供的文件不存在。
    [HINT] 检查文件路径。  
    ```

8. **指定文件格式异常**  

    ```cmd
    >>>ERR 8<<< FILE FORMAT ERROR
    [CAUSE] 文件格式不正确。
    [HINT] 确保文件为有效的 YML 文件。  
    ```

9. **合并时存在冲突的键**  

    ```cmd
    >>>ERR 9<<< MERGE CONFLICT
    [CAUSE] 合并文件时存在冲突的键。
    [HINT] 手动调整冲突的键值对或使用替换功能。  
    ```

10. **限制写入下新建键**  

    ```cmd
    >>>ERR 10<<< KEY CREATION RESTRICTED
    [CAUSE] 限制写入模式下无法新建键。
    [HINT] 确保键已存在或使用普通写入模式。  
    ```

11. **键名无效**  

    ```cmd
    >>>ERR 11<<< INVALID KEY NAME
    [CAUSE] 键名不符合命名规则。
    [HINT] 请检查键名是否符合规范。  
    ```

12. **无法解析正则表达式**  

    ```cmd
    >>>ERR 12<<< REGEX PARSING ERROR
    [CAUSE] 无法解析提供的正则表达式。
    [HINT] 请确保正则表达式格式正确。  
    ```

13. **文件路径无效**  

    ```cmd
    >>>ERR 13<<< INVALID FILE PATH
    [CAUSE] 文件路径无效或格式错误。
    [HINT] 请检查文件路径是否正确并使用绝对路径。  
    ```

14. **权限不足**  

    ```cmd
    >>>ERR 14<<< INSUFFICIENT PERMISSIONS
    [CAUSE] 当前用户权限不足，无法访问或修改文件/剪贴板。
    [HINT] 请确保具有必要的权限（如管理员权限）。  
    ```

15. **YML文件冲突**  

    ```cmd
    >>>ERR 15<<< YML FILE CONFLICT
    [CAUSE] cvcli.yml 文件被其他程序占用或修改，无法正常操作。
    [HINT] 请检查是否有其他程序正在使用该文件。  
    ```