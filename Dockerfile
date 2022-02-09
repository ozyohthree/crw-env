FROM registry.access.redhat.com/ubi8/ubi:latest

LABEL name="ocp-dev" \
      version="0.0.1" \
      release="1" \
      summary="A generic container for developing on OpenShift." \
      description="A generic container with common tools for developing on OpenShift."

RUN dnf update -y && \
    dnf install -y git python3-pip python3-cryptography nodejs npm && \
    dnf clean all -y && \
    /usr/bin/pip3 install --no-cache-dir ansible github3.py openshift && \
    curl -o /tmp/openshift-client-linux.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz && \
    tar -xzvf /tmp/openshift-client-linux.tar.gz -C /usr/local/bin/ && \
    chmod +x /usr/local/bin/oc && \
    rm /usr/local/bin/README.md && \
    rm /usr/local/bin/kubectl && \
    rm /tmp/openshift-client-linux.tar.gz && \
    curl -s "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" | bash && \
    mv /usr/local/bin/helm /usr/bin/helm && \
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash && \
    mv ./kustomize /usr/bin/kustomize && \
    dnf -y module enable container-tools:rhel8; dnf -y update; rpm --restore --quiet shadow-utils; \
    dnf -y install crun podman fuse-overlayfs /etc/containers/storage.conf --exclude container-selinux; \
    rm -rf /var/cache /var/log/dnf* /var/log/yum.*

RUN useradd podman; \
    echo podman:10000:5000 > /etc/subuid; \
    echo podman:10000:5000 > /etc/subgid;

VOLUME /var/lib/containers
RUN mkdir -p /home/podman/.local/share/containers
RUN chown podman:podman -R /home/podman
VOLUME /home/podman/.local/share/containers

RUN curl -o containers.conf  https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/containers.conf && \
    mv /containers.conf /etc/containers/containers.conf && \
    curl -o podman-containers.conf  https://raw.githubusercontent.com/containers/libpod/master/contrib/podmanimage/stable/podman-containers.conf && \
    mkdir -p /home/podman/.config/containers && \
    mv /podman-containers.conf /home/podman/.config/containers/containers.conf && \

# chmod containers.conf and adjust storage.conf to enable Fuse storage.
RUN chmod 644 /etc/containers/containers.conf; sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers /var/lib/shared/vfs-images /var/lib/shared/vfs-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock; touch /var/lib/shared/vfs-images/images.lock; touch /var/lib/shared/vfs-layers/layers.lock

ENV _CONTAINERS_USERNS_CONFIGURED=""

# Install node version manager
# USER 1001
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
