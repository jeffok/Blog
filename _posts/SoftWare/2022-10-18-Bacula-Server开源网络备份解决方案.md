---
title: Bacula Server开源网络备份解决方案
date: 2022-10-18 08:36:00
tags: ["MySQL", "数据库", "MariaDB", "脚本", "Bash"]
categories: ['SoftWare']
render_with_liquid: false
permalink: /posts/2022-10-18-Bacula-Server开源网络备份解决方案/
---

### 介绍

Bacula是一种开源网络备份解决方案，允许您创建备份并执行计算机系统的数据恢复。它非常灵活和强大，这使得它在配置时稍微麻烦，适合在许多情况下进行备份。备份系统是大多数服务器基础架构中的重要组件，因为从数据丢失中恢复通常是灾难恢复计划的关键部分。

在CentOS 7服务器上安装和配置Bacula的服务器组件。我们将配置Bacula执行每周作业，创建本地备份（即其自己的主机的备份）

> 开源产品Ubackup:  https://github.com/lustlost/ubackup<br>
> 开源产品Bacula:  https://www.bacula.org/

<div style='display: none'>
哈哈我是注释，不会在浏览器中显示。
https://www.ixdba.net/archives/category/storage/page/3
https://www.ixdba.net/archives/2012/06/61.htm
https://www.ixdba.net/archives/2012/06/65.htm
https://www.ixdba.net/archives/2012/06/68.htm
https://www.ixdba.net/archives/2012/06/71.htm
</div>

### Bacula组件概述

虽然Bacula由几个软件组件组成，但它遵循服务器 - 客户端备份模型; 为了简化讨论，我们将更多地关注备份服务器和备份客户端，而不是单个Bacula组件。尽管如此，对各种Bacula组件的粗略了解仍然很重要，所以我们现在就讨论它们。

Bacula 服务器，我们也称之为“备份服务器”，具有以下组件：

- Bacula Director（DIR）：控制由文件和存储守护程序执行的备份和还原操作的软件
- 存储后台程序（SD）： 在用于备份的存储设备上执行读写操作的软件
- 目录：维护备份文件数据库的服务。数据库存储在SQL数据库中，例如MySQL或PostgreSQL
- Bacula控制台：一个命令行界面，允许备份管理员与Bacula Director进行交互和控制

注意：Bacula服务器组件不需要在同一台服务器上运行，但它们是一起工作以提供备份服务器功能。

Bacula 客户端，即将要备份的服务器，运行文件守护程序（FD）组件。文件守护程序是一种软件，它为Bacula服务器（特别是Director）提供对要备份的数据的访问。我们还将这些服务器称为“备份客户端”或“客户端”。

正如我们在介绍中所提到的，我们将配置备份服务器以创建其自己的文件系统的备份。这意味着备份服务器也将是备份客户端，并将运行文件守护程序组件。

### 安装Bacula和MySQL

Bacula使用SQL数据库（如MySQL或PostreSQL）来管理其备份目录。在本教程中，我们将使用MariaDB，它是MySQL的替代品。

使用yum安装Bacula和MariaDB Server软件包：

```bash
sudo yum install -y bacula-director bacula-storage bacula-console bacula-client mariadb-server

```

安装完成后，我们需要使用以下命令启动MySQL：

```bash
sudo systemctl start mariadb

```

现在已经安装并运行了MySQL（MariaDB），让我们用这些脚本创建Bacula数据库用户和表：

```sql
/usr/libexec/bacula/grant_mysql_privileges
/usr/libexec/bacula/create_mysql_database -u root
/usr/libexec/bacula/make_mysql_tables -u bacula

```

接下来，我们要运行一个简单的安全脚本，它将删除一些危险的默认值并锁定对我们的数据库系统的访问。运行以下命令启动交互式脚本：

```bash
sudo mysql_secure_installation

```

提示将询问您当前的root密码。由于您刚刚安装了MySQL，因此您很可能没有安装MySQL，因此请按Enter键将其留空。然后提示将询问您是否要设置root密码。继续点击Enter，然后设置密码。对于其他问题，您只需在Enter每个提示中单击按键即可接受默认值。这将删除一些示例用户和数据库，禁用远程root登录，并加载这些新规则，以便MySQL立即尊重我们所做的更改。

现在我们需要为Bacula数据库用户设置密码。

以root用户身份进入MySQL控制台

```text
mysql -u root -p

```

在提示符下输入您刚刚设置的MySQL root密码。

现在设置Bacula数据库用户的密码。使用此命令，但用强密码替换突出显示的“bacula db password”：

```sql
UPDATE mysql.user SET Password=YOUR_PASSWORD'bacula_db_password') WHERE User='bacula';
FLUSH PRIVILEGES;

```

完成后，退出MySQL提示符：`exit`

启用MariaDB以启动时启动。使用以下命令执行此操作：`sudo systemctl enable mariadb`

### 设置Bacula使用MySQL库

默认情况下，Bacula设置为使用PostgreSQL库。因为我们使用MySQL，所以我们需要将其设置为使用MySQL库。

运行此命令：

```sql
sudo alternatives --config libbaccats.so

```

您将看到以下提示。输入1（MySQL）：

```sql
There are 3 programs which provide 'libbaccats.so'.
​
  Selection    Command

----------------------------------------------
   1           /usr/lib64/libbaccats-mysql.so
   2           /usr/lib64/libbaccats-sqlite3.so

* + 3           /usr/lib64/libbaccats-postgresql.so
​
Enter to keep the current selection[+], or type selection number: 1

```

现在安装了Bacula服务器（和客户端）组件。让我们创建备份和恢复目录。

### 创建备份和还原目录

Bacula需要一个备份目录 - 用于存储备份存档 - 并恢复目录 - 将放置已恢复的文件。如果您的系统有多个分区，请确保在具有足够空间的目录上创建目录。

让我们为这两个目的创建新目录：

```bash
sudo mkdir -p /bacula/backup /bacula/restore

```

我们需要更改文件权限，以便只有bacula进程（和超级用户）才能访问这些位置：

```bash
sudo chown -R bacula:bacula /bacula
sudo chmod -R 700 /bacula

```

现在我们准备好配置Bacula Director了。

### 配置Bacula Director

Bacula有几个组件必须独立配置才能正常运行。配置文件都可以在/etc/bacula目录中找到。

我们将从Bacula总监开始。

在您喜欢的文本编辑器中打开Bacula Director配置文件。我们将使用vi：

```bash
sudo vi /etc/bacula/bacula-dir.conf

```

### 配置Director资源

找到Director资源，并通过添加此处显示的DirAddress行将其配置为侦听127.0.0.1（localhost）：

```ini
Director {                            # define myself
  Name = bacula-dir
  DIRport = 9101                # where we listen for UA connections
  QueryFile = "/etc/bacula/query.sql"
  WorkingDirectory = "/var/spool/bacula"
  PidDirectory = "/var/run"
  Maximum Concurrent Jobs = 1
  Password = "YOUR_PASSWORD"         # Console password
  Messages = Daemon
  DirAddress = 127.0.0.1
}

```

现在转到文件的其余部分。

### 配置本地作业

Bacula作业用于执行备份和还原操作。作业资源定义特定作业将执行的操作的详细信息，包括客户端的名称，要备份或还原的FileSet等。

在这里，我们将配置将用于执行本地文件系统备份的作业。

在Director配置中，找到名为“BackupClient1” 的Job资源（搜索“BackupClient1”）。将Name值更改为“BackupLocalFiles”，所以它看起来像这样：

```ini
Job {
  Name = "BackupLocalFiles"
  JobDefs = "DefaultJob"
}

```

接下来，找到名为“RestoreFiles” 的作业资源（搜索“RestoreFiles”）。在这项工作中，您想要更改两件事：将Name值更新为“RestoreLocalFiles”，将Where值更新为“/ bacula / restore”。它应该如下所示：

```ini
Job {
  Name = "RestoreLocalFiles"
  Type = Restore
  Client=BackupServer-fd
  FileSet="Full Set"
  Storage = File
  Pool = Default
  Messages = Standard
  Where = /bacula/restore
}

```

这会将RestoreLocalFiles作业配置为将文件还原到我们之前创建的/bacula/restore目录。

### 配置文件集

Bacula FileSet定义一组文件或目录，以包含或排除备份选择中的文件，并由作业使用

找到名为“Full Set”的FileSet资源（它位于注释中，“＃要备份的文件列表”）。在这里，我们将进行三项更改：（1）添加选项以使用gzip压缩我们的备份，（2）将包含文件/usr/sbin更改为/，以及（3）在“排除”部分下添加File = /bacula。删除注释后，它应如下所示：\

```ini
FileSet {
  Name = "Full Set"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
File = /
}
  Exclude {
    File = /var/lib/bacula
    File = /proc
    File = /tmp
    File = /.journal
    File = /.fsck
    File = /bacula
  }
}

```

让我们回顾一下我们对“Full Set”文件集所做的更改。首先，我们在创建备份存档时启用了gzip压缩。其次，我们要包括/备份，即根分区。第三，我们排除/bacula因为我们不想冗余备份我们的Bacula备份和恢复文件。

注意:如果您有挂载在/中的分区，并且希望将这些分区包含在FileSet中，则需要为每个分区添加额外的文件记录。

请记住，如果在备份作业中始终使用广泛的文件集（如“完整集”），则备份将需要比备份选择更具体的磁盘空间更多的磁盘空间。例如，只有包含自定义配置文件和数据库的FileSet可能足以满足您的需求，如果您有明确的恢复计划，详细说明安装所需的软件包并将恢复的文件放在适当的位置，而只使用一小部分备份存档的磁盘空间。

### 配置存储后台程序连接

在Bacula Director配置文件中，Storage资源定义Director应连接到的Storage Daemon。我们将在短时间内配置实际的存储守护进程。

找到存储资源，并使用localhost备份服务器的专用FQDN（或专用IP地址）替换Address的值。它应该看起来像这样（替换Address=后的词组）：

```ini
Storage {
  Name = File

# Do not use "localhost" here

  Address = backup_server_private_FQDN                # N.B. Use a fully qualified name here
  SDPort = 9103
  Password = "YOUR_PASSWORD"
  Device = FileStorage
  Media Type = File
}

```

这是必要的，因为我们要将存储守护进程配置为侦听专用网络接口，以便远程客户端可以连接到它。

### 配置目录连接

在Bacula Director配置文件中，Catalog资源定义Director应使用和连接的数据库的位置。

找到名为“MyCatalog”的目录资源（它位于“通用目录服务”的注释下），并更新其dbpassword值，使其与您为bacula MySQL用户设置的密码相匹配：

```bash
# Generic catalog service

Catalog {
  Name = MyCatalog

# Uncomment the following line if you want the dbi driver

# dbdriver = "dbi:postgresql"; dbaddress = 127.0.0.1; dbport =

  dbname = "bacula"; dbuser = "bacula"; dbpassword = "YOUR_PASSWORD"
}

```

这将允许Bacula Director连接到MySQL数据库。

### 配置池

Pool资源定义了Bacula用于写入备份的存储集。我们将使用文件作为我们的存储卷，我们只需更新标签，以便我们的本地备份得到正确标记。

找到名为“File”的池资源（它位于注释“＃File Pool definition”下），并添加一行指定标签格式。当你完成时它应该是这样的：

```bash
# File Pool definition

Pool {
  Name = File
  Pool Type = Backup
  Label Format = Local-
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Retention = 365 days         # one year
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
  Maximum Volumes = 100               # Limit number of Volumes in Pool
}

```

保存并退出。你终于完成了Bacula Director的配置。

### 检查Director配置：

让我们验证您的Director配置文件中没有语法错误：

```bash
sudo bacula-dir -tc /etc/bacula/bacula-dir.conf

```

如果没有错误消息，则您的bacula-dir.conf文件没有语法错误。

接下来，我们将配置存储守护程序。

### 配置存储守护程序

我们的Bacula服务器几乎已经建立，但我们仍然需要配置存储守护进程，因此Bacula知道存储备份的位置。
在您喜欢的文本编辑器中打开SD配置。我们将使用vi：

```bash
sudo vi /etc/bacula/bacula-sd.conf

```

### 配置存储资源

查找存储资源。这定义了SD进程侦听连接的位置。添加SDAddress参数，并将其分配给备份服务器的专用FQDN（或专用IP地址）：

```ini
Storage {                             # definition of myself
  Name = BackupServer-sd
  SDPort = 9103                  # Director's port
  WorkingDirectory = "/var/lib/bacula"
  Pid Directory = "/var/run/bacula"
  Maximum Concurrent Jobs = 20
  SDAddress = backup_server_private_FQDN
}

```

### 配置存储设备

接下来，找到名为“FileStorage”的Device资源（搜索“FileStorage”），并更新匹配备份目录的Archive Device值：

```ini
Device {
  Name = FileStorage
  Media Type = File
  Archive Device = /bacula/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
}

```

保存并退出。

### 验证存储后台驻留程序配置

让我们验证您的Storage Daemon配置文件中是否存在语法错误：

```bash
sudo bacula-sd -tc /etc/bacula/bacula-sd.conf

```

如果没有错误消息，则您的bacula-sd.conf文件没有语法错误。

我们已经完成了Bacula配置。我们准备重新启动Bacula服务器组件。

### 设置Bacula组件密码

每个Bacula组件（例如Director，SD和FD）都具有用于组件间身份验证的密码 - 您可能会在浏览配置文件时注意到占位符。可以手动设置这些密码，但是，因为您实际上不需要知道这些密码，我们将运行命令来生成随机密码并将它们插入到各种Bacula配置文件中。

这些命令生成并设置Director密码。该bconsole所连接到的Director，所以它也需要的密码：

YOUR_PASSWORD
DIR_PASSWORD=YOUR_PASSWORD +%s | sha256sum | base64 | head -c 33`
sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" /etc/bacula/bacula-dir.conf
sudo sed -i "s/@@DIR_PASSWORD@@/${DIR_PASSWORD}/" /etc/bacula/bconsole.conf

```

这些命令生成并设置存储后台程序密码。Director连接到SD，因此它也需要密码：

YOUR_PASSWORD
SD_PASSWORD=YOUR_PASSWORD +%s | sha256sum | base64 | head -c 33`
sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" /etc/bacula/bacula-sd.conf
sudo sed -i "s/@@SD_PASSWORD@@/${SD_PASSWORD}/" /etc/bacula/bacula-dir.conf

```

这些命令生成并设置本地文件守护程序（Bacula客户端软件）密码。Director连接到此FD，因此它也需要密码：

YOUR_PASSWORD
FD_PASSWORD=YOUR_PASSWORD +%s | sha256sum | base64 | head -c 33`
sudo sed -i "s/@@FD_PASSWORD@@/${FD_PASSWORD}/" /etc/bacula/bacula-dir.conf
sudo sed -i "s/@@FD_PASSWORD@@/${FD_PASSWORD}/" /etc/bacula/bacula-fd.conf

```

现在我们准备开始我们的Bacula组件了！

### 启动Bacula组件

使用以下命令启动Bacula Director，Storage Daemon和本地File Daemon：

```bash
sudo systemctl start bacula-dir
sudo systemctl start bacula-sd
sudo systemctl start bacula-fd

```

如果它们都正确启动，请运行这些命令，以便它们在启动时自动启动：

```bash
sudo systemctl enable bacula-dir
sudo systemctl enable bacula-sd
sudo systemctl enable bacula-fd

```

让我们通过运行备份作业来测试Bacula的工作原理。

### 测试备份作业

我们将使用Bacula控制台运行我们的第一个备份作业。如果它运行没有任何问题，我们将知道Bacula配置正确。
现在使用以下命令进入控制台：

```bash
sudo bconsole

```

这将带您进入Bacula Console提示符，由*提示符表示。

### 创建标签

首先发出label命令：

```text
label

```

系统将提示您输入卷名。输入您想要的任何名称：

```text
MyVolume

```

然后选择备份应使用的池。我们将使用之前配置的“文件”池，输入“2”：

```text
2

```

### 手动运行备份作业

Bacula现在知道我们如何为备份写入数据。我们现在可以运行我们的备份来测试它是否正常工作：

```dockerfile
run

```

系统将提示您选择要运行的作业。我们想要运行“BackupLocalFiles”作业，因此在提示符处输入“1”：

```text
1

```

在“运行备份作业”确认提示下，查看详细信息，然后输入“是”以运行作业：

```text
yes

```

### 检查消息和状态

在完成一份工作后，Bacula会告诉你，你有消息。消息是通过运行作业生成的输出。

键入以下内容检查邮件：

```text
messages

```

消息应显示“找不到先前的完整备份作业记录”，并且备份作业已启动。如果有任何错误，那就是错误的，他们应该给你一个关于工作没有运行的提示。

查看作业状态的另一种方法是检查Director的状态。要执行此操作，请在bconsole提示符处输入以下命令：

```text
status director

```

如果一切正常，您应该看到您的工作正在运行。像这样的东西：

```dockerfile
Running Jobs:
Console connected at 09-Apr-18 12:16
 JobId Level   Name                       Status
======================================================================
     3 Full    BackupLocalFiles.2018-04-09_12.31.41_06 is running
====

```

当您的工作完成后，它将移至状态报告的“已终止作业”部分，如下所示：

```text
Terminated Jobs:
 JobId  Level    Files      Bytes   Status   Finished        Name
====================================================================
     3  Full    161,124    877.5 M  OK       09-Apr-18 12:34 BackupLocalFiles

```

“OK”状态表示备份作业运行没有任何问题。恭喜！您有Bacula服务器的“Full Set”备份。

下一步是测试还原作业。

### 测试还原作业

现在已经创建了备份，检查它是否可以正确恢复非常重要。该restore命令将允许我们恢复已备份的文件。

### 运行还原所有作业

为了演示，我们将恢复上次备份中的所有文件：

```text
restore all

```

将出现一个选择菜单，其中包含许多不同的选项，用于标识要从中还原的备份集。由于我们只有一个备份，让我们“选择最新的备份” - 选择选项5：

```text
5

```

因为只有一个客户端，Bacula服务器，它将自动被选中。

下一个提示将询问您要使用哪个FileSet。选择“Full Set”，应为2：

```text
2

```

这将使您进入一个虚拟文件树，其中包含您备份的整个目录结构。这种类似shell的界面允许简单的命令来标记和取消标记要恢复的文件。

因为我们指定要“全部恢复”，所以每个备份文件都已标记为要恢复。标记的文件由前导*字符表示。

如果您想微调您的选择，您可以使用“ls”和“cd”命令导航和列出文件，使用“mark”标记要恢复的文件，并使用“unmark”取消标记文件。通过在控制台中键入“help”，可以获得完整的命令列表。

完成恢复选择后，请键入以下内容：

```text
done

```

确认您要运行还原作业：

```text
yes

```

### 检查消息和状态

与备份作业一样，应在运行还原作业后检查消息和Director状态。

键入以下内容检查邮件

```text
messages

```

应该有一条消息表明还原作业已启动或已终止并具有“还原正常”状态。如果有任何错误，那就是错误的，他们应该给你一个关于工作没有运行的提示。

同样，检查Director状态是查看还原作业状态的好方法：

```text
status director

```

完成还原后，键入exit以退出Bacula控制台：

```text
exit

```

### 验证还原

要验证还原作业是否实际还原了所选文件，您可以查看/bacula/restore目录（在Director配置中的“RestoreLocalFiles”作业中定义）：

```bash
sudo ls -la /bacula/restore

```

您应该在根文件系统中看到已还原的文件副本，不包括“RestoreLocalFiles”作业的“排除”部分中列出的文件和目录。如果您尝试从数据丢失中恢复，则可以将还原的文件复制到适当的位置。

### 删除已还原的文件

您可能希望删除已还原的文件以释放磁盘空间。为此，请使用以下命令：

```bash
sudo -u root bash -c "rm -rf /bacula/restore/*"

```

请注意，您必须以root身份运行此rm命令，因为许多还原的文件都归root所有。

### 结论

您现在有一个基本的Bacula设置，可以备份和恢复本地文件系统。下一步是将其他服务器添加为备份客户端，以便在数据丢失时恢复它们。