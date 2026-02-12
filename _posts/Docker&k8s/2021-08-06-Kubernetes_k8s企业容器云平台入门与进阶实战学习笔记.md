---
title: Kubernetes_k8s企业容器云平台入门与进阶实战学习笔记
date: 2021-08-06 14:18:00
tags: ["容器", "Kubernetes", "K8s"]
categories: ["Docker&k8s"]
render_with_liquid: false
permalink: /posts/2021-08-06-Kubernetes_k8s企业容器云平台入门与进阶实战学习笔记/
---

本文档介绍 Kubernetes_k8s企业容器云平台入门与进阶实战学习笔记 的相关内容。

## kubernetes 概述

### 什么是kubernetes

* kubernetes是Google在2014年开源的一个容器集群管理系统，kubernetes简称k8s.
* k8s用于容器化应用程序的部署，扩展和管理。
* k8s提供了容器编排，资源调度，弹性伸缩，部署管理，服务发现等一系列功能。
* kubernetes目标是让部署容器化应用简单高效。
官方网站：http://www.kubernetes.io

### kubernetes的特性

* 自我修复 <br>
在节点故障时重新启动失败的容器，替换和重新部署，保证预期的副本数量；杀死健康检查失败的容器，并且在未准备好之前不会处理客户端请求，确保线上服务不中断。

* 弹性伸缩<br>
使用命令、UI或者基于CPU使用情况自动快速扩容缩容应用程序实例，保证应用业务高峰并发时的高可用性；业务低峰时回收资源，以最小成本运行服务。

* 自动部署和回滚<br>
k8s采用滚动更新策略更新应用，一次更新一个Pod，如果更新过程中出现问题，将回滚更改，确保升级不受影响业务。

* 服务发现和负载均衡 <br>
k8s为多个容器提供一个统一访问入口（内部IP地址和一个DNS名称），并且负载均衡关联的所有容器，使得用户无需考虑容器的IP问题。

* 机密和配置管理 <br>
管理机密数据和应用程序配置，而不需要把敏感数据暴露在镜像里，提高敏感数据安全性。并可以将一些常用的配置存储在k8s中，方便应用程序使用。

* 存储编排 <br>
挂载外部存储系统，无论来自己本地存储，公有云（如AWS）,还是网络存储（如NFS,GlusterFS,Ceph）都作为集群资源的一部分使用，极大提高存储使用灵活性。

* 批处理 <br>
提供一次性任务，定时任务；满足批量数据处理和分析的场景。

### kubernetes架构与组件

#### 架构图 <br>

<img src=http://note.youdao.com/yws/res/3232/EE5D5D9E440E4EAE9A5CB69AA0297EF0 width=800>

#### Master组件

* kube-apiserver <br>
Kubernetes API，集群的统一入口，各组件协调者，以RESTful API提供接口服务，所有对象资源的增删改查和监听操作都交给APIserver处理后再提交给Etcd存储。

* kube-controller-manager <br>
处理集群中常规后台任务，一个资源对应一个控制器，而ControllerManager就是负责管理这些控制器的。

* kube-scheduler <br>
根据调度算法为新创建的Pod选择一个Node节点，可以任意部署，可以部署在同一个节点上，也可以部署在不同的节点上。

* etcd <br>
分布式键值存储系统。用于保存集群状态数据，比如Pod、Service等对象信息。

#### Node组件

* kubelet <br>
kubelet是Master在Node节点上的Agent,管理本机运行容器的生命周期，比如创建、Pod挂载数据卷、下载secret、获取容器和节点状态等工作。kubelet将每个Pod转换成一组容器。

* kube-proxy <br>
在Node节点上实现Pod网络代理，维护网络规则和四层负载均衡工作。

* docker或rocket <br>
容器引擎，运行容器。

### kubernetes核心概念

* Pod
    * 最小部署单元
    * 一组容器的集合
    * 一个pod中的容器共享网络命名空间
    * pod是短暂的

* Controllers
    * ReplicaSet: 确保预期的Pod副本数量
    * Deployment: 无状态应用部署
    * StatefulSet: 有状态应用部署
    * DaemonSet: 确保所有Node运行同一个Pod
    * Job: 一次性任务
    * Cronjob: 定时任务 <br>
更高层次对象，部署和管理Pod

* Service
    * 防止Pod失联
    * 定义一组Pod的访问策略

* Label: 标签，附加到某个资源上，用于关联对象、查询和筛选
* Namespace: 命名空间，将对象逻辑上隔离

## 搭建一个完整的kubernetes集群

### 生产环境k8s平台规划

#### 单Master集群

<img src=http://note.youdao.com/yws/res/3278/E828B8E8F6E34214BC4F7451A50E37B6 width=500>

#### 多Master集群(HA)

<img src=http://note.youdao.com/yws/res/3281/9D12735BE9A04E6085C029C46449ABD5 width=500>

#### 平台规划

角色 | IP | 组件

- --|---|---
k8s-master1 | 192.168.1.1 | kube-apiserver <br>kube-controller-manager <br>kube-scheduler <br>etcd
k8s-master2 | 192.168.1.2 | kube-apiserver <br>kube-controller-manager <br>kube-scheduler <br>etcd
k8s-node1 | 192.168.1.3 | kubelet <br>kube-proxy <br>docker <br>etcd
k8s-node2 | 192.168.1.4 | kubelet <br>kube-proxy <br>docker
Load Balancer(master) | 192.168.1.11 <br>==192.168.1.10(VIP)== | Nginx L4
Load Balancer(Backup) | 192.168.1.12 | Nginx L4

### 服务器三件配置推荐

#### 硬件配置推荐

实验环境 | k8s master/node | 2C2G+

- --|---|---

### 官方提供三种部署方式

### 为Etcd和APIserver自签SSL证书

### Etcd数据库集群部署

### 部署Master组件

### 部署Node组件

### 部署k8s集群网络

### 部署Web Ui (Dashboard)

### 部署集群内部DNS解析服务(CoreDNS)
