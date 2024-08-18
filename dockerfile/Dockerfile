FROM ubuntu:20.04
ENV USER=dev
ENV PASSWD=dev
ARG DEBIAN_FRONTEND=noninteractive

# 阿里云源
RUN printf '\n\
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse \n\
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse \n\
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse \n\
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse \n\
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse \n\
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse \n\
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse \n\
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse' > /etc/apt/sources.list

# 安装开发环境必要的包
RUN apt-get update \
  && apt-get install -y  \
  ssh openssh-server \
  build-essential gcc g++ gdb gdbserver cmake clangd \
  python3 python3-pip \
  sudo git\
  && apt-get clean \
  && pip3 install compiledb

# 添加用户并配置密码
# 赋予sudo权限并允许无密码sudo
RUN useradd -m ${USER} && \
    echo "${USER}:${PASSWD}" | chpasswd && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod 440 /etc/sudoers

USER ${USER}
ENV LC_ALL C.UTF-8
