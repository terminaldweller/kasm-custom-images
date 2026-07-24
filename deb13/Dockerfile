ARG BASE_TAG="1.19.0"
ARG BASE_IMAGE="core-debian-trixie"
FROM kasmweb/$BASE_IMAGE:$BASE_TAG

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR $HOME

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=$STARTUPDIR/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=$STARTUPDIR/install \
    INST_SCRIPTS="/ubuntu/install/tools/install_tools_deluxe.sh \
                  /ubuntu/install/misc/install_tools.sh \
                  /ubuntu/install/firefox/install_firefox.sh \
                  /ubuntu/install/cleanup/cleanup.sh"

COPY ./src/ $INST_DIR

RUN \
  for SCRIPT in $INST_SCRIPTS; do \
    bash ${INST_DIR}${SCRIPT} || exit 1; \
  done && \
  $STARTUPDIR/set_user_permission.sh $HOME && \
  rm -f /etc/X11/xinit/Xclients && \
  chown 1000:0 $HOME && \
  mkdir -p /home/kasm-user && \
  chown -R 1000:0 /home/kasm-user && \
  rm -Rf ${INST_DIR}

RUN apt update && apt install -y build-essential gdb clang vim-nox tmux curl wget git ripgrep fd-find bind9-dnsutils socat zsh zsh-syntax-highlighting zsh-autosuggestions autoconf cmake meson ninja-build irssi profanity lf bat python3-pip pipx

RUN rm -rf /home/kasm-default-profile/.cache

USER 1000
WORKDIR /home/kasm-default-profile
ENV HOME=/home/kasm-default-profile

RUN curl -L -s https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/DejaVuSansMono.tar.xz -o DejaVuSansMono.tar.xz && tar -xvf DejaVuSansMono.tar.xz && mkdir ~/.fonts && mv DejaVuSansMNerdFont* ~/.fonts && rm DejaVuSansMono.tar.xz
RUN curl -L -s https://github.com/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-gnu.tar.gz -o eza.tar.gz && tar -xvf eza.tar.gz && mkdir -p ~/.local/bin && mv eza ~/.local/bin && rm eza.tar.gz
RUN curl -L -s https://github.com/junegunn/fzf/releases/download/v0.74.1/fzf-0.74.1-linux_amd64.tar.gz -o fzf.tar.gz && tar -xvf fzf.tar.gz && mkdir -p ~/.local/bin && mv fzf ~/.local/bin && rm fzf.tar.gz
RUN curl https://mise.run | sh
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN git clone https://github.com/terminaldweller/scripts && git clone https://github.com/terminaldweller/minimalrc && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN mkdir devi &&\
      cd devi &&\
      git clone https://github.com/junegunn/fzf &&\
      git clone https://github.com/junegunn/fzf-git.sh
RUN git clone https://github.com/romkatv/powerlevel10k
RUN /home/kasm-default-profile/.local/bin/mise install go@latest
RUN cp /home/kasm-default-profile/scripts/.dir_colors /home/kasm-default-profile/.dir_colors
RUN cp /home/kasm-default-profile/minimalrc/.zshrc /home/kasm-default-profile/.zshrc
RUN cp /home/kasm-default-profile/minimalrc/.p10k.zsh /home/kasm-default-profile/.p10k.zsh
RUN cp /home/kasm-default-profile/minimalrc/.tmux.conf /home/kasm-default-profile/.tmux.conf
RUN cp /home/kasm-default-profile/scripts/.inputrc /home/kasm-default-profile/.inputrc
RUN cp /home/kasm-default-profile/minimalrc/.vimrc /home/kasm-default-profile/.vimrc

ENV HOME=/home/kasm-user
WORKDIR $HOME
USER 1000

CMD ["--tail-log"]
