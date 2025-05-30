FROM ubuntu:20.04
ENV PASSWD=1234
ARG USER=leo
ARG HOME=/home/${USER}
ARG DEBIAN_FRONTEND=noninteractive

# 阿里云源
RUN sed -i 's/^\(deb\|deb-src\) \([^ ]*\) \(.*\)/\1 http:\/\/mirrors.aliyun.com\/ubuntu \3/' \
  /etc/apt/sources.list

# 安装开发环境必要的包
RUN apt-get update \
  && apt-get install -y  \
  ssh openssh-server \
  build-essential gcc g++ gdb gdbserver cmake clangd libboost-all-dev \
  zsh npm wget curl \
  gettext libgettextpo-dev \
  bison libncurses-dev \
  python3 python3-pip python3.8-venv\
  sudo git unzip\
  && apt-get clean \
  && pip3 install compiledb

# 安装neovim
# 下载github最新包，直接安装到/usr/local目录下
RUN cd /tmp && wget "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz" \
  && tar xzf nvim-linux64.tar.gz && cd nvim-linux64 \
  && cp -rf bin/* /usr/local/bin && cp -rf lib/* /usr/local/lib && cp -rf share/* /usr/local/share \
  && cd /tmp && rm -rf /tmp/nvim-*

# 安装tmux
RUN cd /tmp && wget https://github.com/tmux/tmux/releases/download/3.5a/tmux-3.5a.tar.gz \
  && tar xzf tmux-3.5a.tar.gz && cd tmux-3.5a \
  && ./configure && make -j && make install \
  && cd /tmp && rm -rf /tmp/tmux-*

# 修正系统时间
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 更新nodejs
RUN npm install -g n && n stable

# 初始化ssh
RUN mkdir /var/run/sshd \
  && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
  && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
  && ssh-keygen -A

# 添加用户并配置密码
# 赋予sudo权限并允许无密码sudo
# 设置默认shell为zsh
RUN useradd -m -d ${HOME} ${USER} && \
    echo "${USER}:${PASSWD}" | chpasswd && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown ${USER}:${USER} -R ${HOME} &&\
    chmod 440 /etc/sudoers && \
    chsh -s /usr/bin/zsh ${USER}

USER ${USER}
ENV LC_ALL C.UTF-8
EXPOSE 22
CMD ["/bin/bash", "-c", "sudo service ssh restart & tail -f /dev/null"]

