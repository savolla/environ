FROM ubuntu:22.04

RUN apt-get update
RUN apt-get install -y sudo neovim vim gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build ranger

RUN rm -rf /var/lib/apt/lists/* # remove apt cache since you don't need this anymore. reduce image size

ARG UID
ARG GID
ARG USERNAME

# Create a user with the specified UID and GID
# RUN groupadd -g $GID $USERNAME && \
RUN useradd -m -u $UID -g $GID -s /bin/bash $USERNAME

RUN echo 'root:docker' | chpasswd
RUN echo 'savolla:docker' | chpasswd
RUN echo "savolla ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/savolla

USER $USERNAME
WORKDIR /home/$USERNAME

CMD ["/bin/bash"]

