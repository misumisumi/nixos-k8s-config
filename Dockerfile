FROM docker.io/nixos/nix:latest
ENV INCUS_HOST 127.0.0.1:8443
ENV DIRENV_WARN_TIMEOUT 300s

RUN touch /etc/nix/nix.conf && \
    echo "sandbox = false" >> /etc/nix/nix.conf && \
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf && \
    echo "max-jobs = 2" >> /etc/nix/nix.conf && \
    echo "cores = 4" >> /etc/nix/nix.conf && \
    echo "keep-outputs = true" >> /etc/nix/nix.conf && \
    echo "keep-derivations = true" >> /etc/nix/nix.conf && \
    echo "auto-optimise-store = true" >> /etc/nix/nix.conf && \
    echo ". $HOME/.nix-profile/share/nix-direnv/direnvrc" >> $HOME/.bashrc && \
    echo ". $HOME/.nix-profile/etc/profile.d/bash_completion.sh" >> $HOME/.bashrc && \
    echo 'eval "$(direnv hook bash)"' >> $HOME/.bashrc && \
    mkdir -p /workdir

RUN nix profile add \
    nixpkgs\#direnv \
    nixpkgs\#nix-direnv \
    nixpkgs\#bash-completion

WORKDIR /workdir
