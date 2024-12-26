FROM ubuntu:20.04
ENV PASSWD=1234
ARG USER=dev
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
  zsh tmux \
  gettext libgettextpo-dev \
  python3 python3-pip \
  sudo git\
  && apt-get clean \
  && pip3 install compiledb

# 安装neovim
# 下载github最新包，直接安装到/usr/local目录下
RUN cd /tmp && wget "https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.tar.gz" \
  && tar xzf nvim-linux64.tar.gz && cd nvim-linux64 \
  && cp -rf bin/* /usr/local/bin && cp -rf lib/* /usr/local/lib && cp -rf share/* /usr/local/share \
  && rm -rf /tmp/nvim-*

# 添加用户并配置密码
# 赋予sudo权限并允许无密码sudo
# 设置默认shell为zsh
RUN useradd -m -d ${HOME} ${USER} && \
    echo "${USER}:${PASSWD}" | chpasswd && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chmod 440 /etc/sudoers && \
    chsh -s /usr/bin/zsh ${USER}

# 切换USER, 安装dotfiles
# RUN sudo -u ${USER} -H bash -c 'cd ~ && mkdir -p .config && cd .config \
#   && rm ~/.bashrc && git clone https://github.com/ravenxrz/dotfiles.git --depth=1 \
#   && cd dotfiles && ./install'

USER ${USER}
ENV LC_ALL C.UTF-8
