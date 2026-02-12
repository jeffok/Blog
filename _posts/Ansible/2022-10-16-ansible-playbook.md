---
title: ansible playbook
date: 2022-10-16 18:34:00
tags: ["自动化", "Ansible"]
categories: ["Ansible"]
render_with_liquid: false
permalink: /posts/2022-10-16-ansible-playbook/
---
> https://www.jianshu.com/p/83416454a588

```ini
# 配置文件ansible.cfg

[defaults]

# some basic default values...

# inventory      = /etc/ansible/hosts   #配置文件路径

# library        = /usr/share/my_modules/

# module_utils   = /usr/share/my_module_utils/

# remote_tmp     = ~/.ansible/tmp

# local_tmp      = ~/.ansible/tmp

# forks          = 5

# poll_interval  = 15

# sudo_user      = root

# ask_sudo_pass = True

# ask_pass      = True

# transport      = smart

# remote_port    = 22

# module_lang    = C

# module_set_locale = False

```

## 基本执行方法

执行 playbook：

```bash
ansible-playbook xxx.yml

```

## playbook 简易示例

```yaml
---
- name: test_playbook
  hosts: jeff_linux
  remote_user: root
  gather_facts: false
  tasks:

    - name: touch /tmp/test.txt
      ansible.builtin.shell: touch /tmp/test.txt

```

说明：

- 第一行 `---` 是 YAML 文档起始标记
- `hosts` 指定对哪些主机/主机组执行（可在 `/etc/ansible/hosts` 定义）
- `remote_user` 指定远程登录用户
- `tasks` 定义任务列表，任务里的 `name` 是执行时打印的说明

## 创建用户的playbook

```yaml
---
- name: create_user
  hosts: jeff_linux
  remote_user: root
  gather_facts: false
  vars:
    user: test
  tasks:

    - name: create user
      ansible.builtin.user:
        name: "{{ user }}"

```

## 循环

```yaml
---
- name: loop example
  hosts: jeff_linux
  remote_user: root
  gather_facts: false
  tasks:

    - name: change mode for files
      ansible.builtin.file:
        path: "/tmp/{{ item }}"
        state: touch
        mode: "0600"
      loop:

        - 1.txt
        - 2.txt
        - 3.txt

```

## 条件判断

先获取 facts（示例）：

```bash
ansible jeff_linux -m setup

```

playbook 示例：

```yaml
---
- name: when example
  hosts: jeff_linux
  remote_user: root
  gather_facts: true
  tasks:

    - name: use when
      ansible.builtin.shell: touch /tmp/when.txt
      when: ansible_eno16777736.ipv4.address == "192.168.133.132"

```

## Handlers

handlers 类似 “任务触发后再执行动作”（例如重启服务）：

```yaml
---
- name: handlers test
  hosts: jeff_linux
  remote_user: root
  gather_facts: false
  tasks:

    - name: copy file
      ansible.builtin.copy:
        src: /etc/passwd
        dest: /tmp/aaab.txt
      notify: test handlers

  handlers:

    - name: test handlers
      ansible.builtin.shell: echo "11111" >> /tmp/aaab.txt

```

## playbook-nginx 安装

调用其它的 yml（示例）：

```yaml
- import_tasks: xxx.yml
- import_tasks: xxx.yml

```

入口文件（roles 示例）：

```yaml
---
- name: nginx role example
  hosts: testhosts
  remote_user: root
  gather_facts: true
  roles:

    - common
    - install

```
