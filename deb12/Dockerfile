ARG BASE_TAG="develop"
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

RUN apt update && apt install -y build-essential gdb clang vim-nox tmux curl wget git ripgrep fd-find bind9-dnsutils socat zsh zsh-syntax-highlighting zsh-autosuggestions autoconf cmake meson ninja-build irssi profanity eza lf bat python3-pip pipx

USER 1000
WORKDIR /home/kasm-user
ENV HOME=/home/kasm-user

RUN curl https://mise.run | sh
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN git clone https://github.com/terminaldweller/scripts && git clone https://github.com/terminaldweller/minimalrc && git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
RUN mkdir devi &&\
      cd devi &&\
      git clone https://github.com/junegunn/fzf &&\
      git clone https://github.com/junegunn/fzf-git.sh
RUN git clone https://github.com/romkatv/powerlevel10k
RUN /home/kasm-user/.local/bin/mise install go@latest
RUN /home/kasm-user/devi/fzf/install --all
RUN cp /home/kasm-user/scripts/.dir_colors /home/kasm-user/.dir_colors
RUN cp /home/kasm-user/minimalrc/.zshrc /home/kasm-user/.zshrc
RUN cp /home/kasm-user/minimalrc/.p10k.zsh /home/kasm-user/.p10k.zsh
RUN cp /home/kasm-user/minimalrc/.tmux.conf /home/kasm-user/.tmux.conf
RUN cp /home/kasm-user/scripts/.inputrc /home/kasm-user/.inputrc
RUN cp /home/kasm-user/minimalrc/.vimrc /home/kasm-user/.vimrc

CMD ["--tail-log"]
