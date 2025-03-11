# cvcli: 更好的在命令行中复制粘贴  

> 项目开发中  

在GUI页面，有很多不错的剪贴板升级工具：如`Ditto`，以及更常用的：通过`Windows + V`键唤醒的Windows剪贴板。  
然而，在命令行界面中，却缺乏类似方便剪贴板工具存在：当我们想要持久化我们的剪贴板时，需要比较复杂的操作。有时，我们想要一个持久化的剪贴板的同时不离开我们的命令行界面。  
**`cvcli`提供了一个命令行的剪贴板键值对存储工具**，由`lua`实现，并使用[`strlua`](https://github.com/LuaDist/srlua)编译为的可执行文件。

---

## 安装  

### 使用安装脚本  

> 安装脚本暂不可用,目前只能执行手动安装  

`cvcli` 提供了安装脚本以实现一键安装的功能。  

- **Windows**:  
  - 从`release`中下载`cvcli-win64.zip`至本地并解压缩  
  - 以管理员身份运行`install.bat`,随后重启设备  
  - 默认情况下，`cvcli` 将安装至 `C:\Program Files\cvcli` 目录  
  - 如果需要更改默认安装路径，请编辑 `install.bat` 中的目标目录配置  

> 目前暂仅支持`Windows`  

### 手动安装  

- **Windows**:  
  - 从`release`中下载`cvcli-win64.zip`至本地并解压缩  
  - 将`program`文件夹中`cvcli.exe`文件移动到你需要安装的目录  
  - 将该目录添加到系统环境变量的 `PATH` 中,随后重启设备  

> 自行构建: 在`build`文件夹运行`build.bat`.项目自带了构建于Win64平台的`srlua`,如需自行构建,访问[srlua项目链接](https://github.com/LuaDist/srlua)  

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
lastkey: ---last--- 
```  

包含了如下信息：  

- **版本**: 0.1  
- **环境**: Windows  
- **存储的键数**: 0  
- **上一个使用的键**: ---last---  

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

### 第一个使用示例  

按照以下代码块的内容,参考你的第一个使用实例:   

```cmd
PS C:\Users\linzh> cvcli -w key1 value1
---WRITTEN IN `key1`---
PS C:\Users\linzh> cvcli key1
---`key1` COPIED TO CLIPBOARD---
PS C:\Users\linzh> cvcli -wv key2
---WRITTEN IN `key2`---
PS C:\Users\linzh> cvcli -l
---`key2` COPIED TO CLIPBOARD---
PS C:\Users\linzh> cvcli -mk "."
FOR key MATCHING: .
---3 RESULTS---
| KEY            |  VALUE |
| key1             |  value1 |
| ---last---       |  key2 |
| key2             |  value1 |
```

以上进行了如下操作:  

1. 向键`key1`写入值`value1`  
2. 读取键`key1`的值并写入剪贴板  
3. 向键`key2`写入当前剪贴板中的值(`value1`)
4. 读取上一个使用的键(`key2`)  
5. 显示当前存储的所有键  

> 由于终端的限制,在显示非ASCII码的字符时可能出现乱码  

---

## 功能指令

### 写入操作

向 `cvcli` 存入数据的标准语法如下：

```bash
cvcli -w [k] [v]
```

- `[k]` 是键名（Key）。
- `[v]` 是值名（Value）。

#### 键的命名规则  

在 `cvcli` 中，键名必须遵守以下规则：  

1. **不能以连续的三个 `-` 开头**（这是 `cvcli` 的保留字）  
2. **不能包含特殊字符**，例如空格    
3. **不能是以下保留字之一：**  
   - `-w`、`-wv`、`-wl`、`-wvl`、`-wr`、`-wvlr`、`-l`、`-mk`、`-mv`、`-cc`、`-cr`  
4. **不超过16个字符**  

键具有唯一性：每个键在 `cvcli` 中是唯一的，重复键会覆盖之前的值。  

#### 写入指令变体

##### 标准写入  

以下示例展示了如何写入键值对：

```bash  
cvcli -w hello "hello world!"
```  

这表示向键 `hello` 写入值 `"hello world!"`。

##### 写入剪贴板中的值  

将当前剪贴板中待粘贴的内容作为值写入：  

```bash  
cvcli -wv [k]
```  

示例：

```bash
cvcli -wv p
```

这表示向键 `p` 写入当前剪贴板中的值。

##### 限制写入到已存在的键

向已存在的键写入指定值：

```bash
cvcli -wr [k] [v]
```

示例：

```bash
cvcli -wr hello "updated value"
```

这表示仅当键 `hello` 已存在时，才向其写入值 `"updated value"`。

### 读取操作

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

### 删除操作

删除指定键及其值：

```bash
cvcli -r [k]
```

示例：

```bash
cvcli -r hello
```

这表示删除键 `hello` 及其对应的值。

### 搜索操作

`cvcli` 支持使用正则表达式进行键名或值的搜索：

> 如需列出全部内容,考虑使用`"."`匹配.如`cvcli -mk "."`即匹配所有的键  

1. **搜索键名：**

   ```bash
   cvcli -mk [pattern]
   ```

   例如：

   ```bash
   cvcli -mk "^h.*"
   ```

   这表示搜索所有以 `h` 开头的键。

2. **搜索值：**

   ```bash
   cvcli -mv [pattern]
   ```

   例如：

   ```bash
   cvcli -mv "world"
   ```

   这表示搜索所有值中包含 `world` 的项。

### 合并或替换文件

`cvcli` 提供了将外部 `.yml` 文件与当前存储合并或替换的功能：

1. **合并文件：**

   ```bash
   cvcli -cc [filename]
   ```

   - `-cc` 表示 *copy and combine*，将指定的 `filename.yml` 文件内容与当前存储合并。
   - 如果出现重复键，将会进入冲突解决界面。  

2. **替换文件：**

   ```bash
   cvcli -cr [filename]
   ```

   - `-cr` 表示 *copy and replace*，将指定的 `filename.yml` 文件内容替换当前存储的内容。
   - 操作前需要三次确认以防止意外数据丢失。
