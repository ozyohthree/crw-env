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

# Install Buildah
# From: https://catalog.redhat.com/software/containers/rhel8/buildah/5dca3d76dd19c71643b226d5?container-tabs=dockerfile
# labels for container catalog
LABEL summary="A command line tool used for creating OCI Images"
LABEL description="The buildah container provides a command line tool which can be used to create a working container from scratch or to create a working container from an image as a starting point. Also to mount/umount a working container's root file system for manipulation, save container's root file system layer to create a new image and delete a working container or an image."
LABEL io.k8s.display-name="Buildah"
LABEL io.openshift.expose-services=""

# Don't include container-selinux and remove
# directories used by yum that are just taking
# up space.
RUN useradd build; dnf -y module enable container-tools:rhel8; dnf -y update; dnf -y reinstall shadow-utils; dnf -y install buildah fuse-overlayfs /etc/containers/storage.conf; rm -rf /var/cache /var/log/dnf* /var/log/yum.*

# Adjust storage.conf to enable Fuse storage.
RUN sed -i -e 's|^#mount_program|mount_program|g' -e '/additionalimage.*/a "/var/lib/shared",' /etc/containers/storage.conf
RUN mkdir -p /var/lib/shared/overlay-images /var/lib/shared/overlay-layers; touch /var/lib/shared/overlay-images/images.lock; touch /var/lib/shared/overlay-layers/layers.lock

# Set up environment variables to note that this is
# not starting with usernamespace and default to
# isolate the filesystem with chroot.
ENV _BUILDAH_STARTED_IN_USERNS="" BUILDAH_ISOLATION=chroot

# Install node version manager
# USER 1001
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
