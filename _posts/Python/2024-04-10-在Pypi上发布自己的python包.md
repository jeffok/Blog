---
title: 在Pypi上发布自己的python包
date: 2024-04-10 08:36:00
tags: ["编程", "Python"]
categories: ["Python"]
render_with_liquid: false
permalink: /posts/2024-04-10-在Pypi上发布自己的python包/
---

## > 简单总结

> 1. 做setup.py 文件，参考模板
> 2. python setup.py sdist build
> 3. sudo pip install twine
> 4. twine upload disk/*

## 打包工作主要依赖于python的一个叫setuptools的包来完成

```bash
pip install setuptools

```

## 注册自己的账号：https://pypi.python.org/pypi

```ini
创建用户验证文件 ~/.pypirc
在自己的用户目录下新建一个空白文件命名为.pypirc，内容如下：

[distutils]
index-servers=pypi

[pypi]
repository = https://upload.pypi.org/legacy/
username = <username>
password = <password>
用户名和密码就是上一步骤所创建的，直接明文输入。如果你觉得明文密码不安全也可以留空，在后面的上传过程中会提示你手动输入。

```

## 准备setup.py、setup.conf 文件，它是放在包的根目录

```bash
# !/usr/bin/env python

# coding=utf-8

from setuptools import setup, find_packages

setup(
    name='<项目的名称>',
    version=<项目版本>,
    description=(
        '<项目的简单描述>'
    ),
    long_description=open('README.rst').read(),
    author='<你的名字>',
    author_email='<你的邮件地址>',
    maintainer='<维护人员的名字>',
    maintainer_email='<维护人员的邮件地址',
    license='BSD License',
    packages=find_packages(),
    platforms=["all"],
    url='<项目的网址，我一般都是github的url>',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Operating System :: OS Independent',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: BSD License',
        'Programming Language :: Python',
        'Programming Language :: Python :: Implementation',
        'Programming Language :: Python :: 2',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Topic :: Software Development :: Libraries'
    ],
)

```

> 需要注意的上面的字段：
> 1. version - 这个简单，就是包的发布的版本，可以直接写在这，也可以从其他地> 方引用过来。
> 2. long_description - 必须是rst（reStructuredText > )格式的，因为这个里面的内容是显示在pypi包首页上，具体rst的语法可以参考：ht> tp://rest-sphinx-memo.readthedocs.io/en/latest/ReST.html.我的long_description是同目录下的README.rst的内容，同时这个README也是我的gi> thub项目首页。
> 3. packages - 申明你的包里面要包含的目录，比如 ['mypackage', > 'mypackage_test'] 可以是这种使用我的示例，让setuptools自动决定要包含哪些包
> 4. install_requires - > 申明依赖包，安装包时pip会自动安装：格式如下（我上面的setup.py没有这个参数> ，因为我不依赖第三方包:)）：

```ini
install_requires=[
        'Twisted>=13.1.0',
        'w3lib>=1.17.0',
        'queuelib',
        'lxml',
        'pyOpenSSL',
        'cssselect>=0.9',
        'six>=1.5.2',
        'parsel>=1.1',
        'PyDispatcher>=2.0.5',
        'service_identity',
    ]

```

## 准备requirements.txt 和 test-requirements.txt，这个申明包的依赖包和跑自动化测试的测试依赖包，具体格式示例如下：

```ini
mock>=2.0.0
flake8>=3.2.1
eventlet>=0.19.0
nose2>=0.6.5
cov_core>=1.15.0
virtualenv>=15.1.0

```

> 以上是我的test-requirements.txt的内容，requirements.txt的格式个上面一样。准备这个两个文件不是必须的。但是，有了它们，用户可以自己手动安装依赖包

```bash
pip install -r requirements.txt

```

有了它们，结合tox等工具，可以非常方便的加入自动化测试。
准备一个项目的README.rst文件,前面也提到了它的格式要求，第一次发包，可以直接copy别人的格式，这东西熟能生巧，多写就会了。
README的截图就不放了，以免广告嫌疑。有兴趣可以到参考http://rest-sphinx-memo.readthedocs.io/en/latest/ReST.html
准备好上面的步骤，一个包就基本完整了，剩下的就是打包了(cd到包的根目录)：
可以使用下面命令打包一个源代码的包:

```bash
python setup.py sdist build

```

这样在当前目录的dist文件夹下，就会多出一个以tar.gz结尾的包了：
也可以打包一个wheels格式的包，使用下面的命令搞定：

```bash
python setup.py bdist_wheel --universal

```

这样会在dist文件夹下生成一个whl文件，
上传生成的包，可以使用setuptools,或者twine上传,推荐使用twine上次，因为使用setuptools上传时，你的用户名和密码是明文或者未加密传输，安全起见还是使用twine吧

```bash
# 上传source 包python

setup.py sdist upload

# 上传pre-compiled包

python setup.py bdist_wheel upload

```

使用twine上传,先安装twine

```bash
sudo pip install twine
twine upload dist/*

```

上次前都会提示你前面注册的用户名和密码。一切搞定，你的包现在可以通过pip在任何地方安装了