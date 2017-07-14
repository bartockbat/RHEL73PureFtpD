FROM registry.access.redhat.com/rhel7

LABEL name="gt-software/ftp" \
      vendor="gt-software" \
      version="1.0.42" \
      release="1" \
      summary="GT-Software FTP app" \
      description="FTP app will do ....." \
### Required labels above - recommended below
      url="https://www.gtsoftware.io" \
      run='docker run -tdi --name ${NAME} ${IMAGE}' \
      io.k8s.description="FTP app will do ....." \
      io.k8s.display-name="FTP app" \
      io.openshift.expose-services="" \
      io.openshift.tags="gt-software,ftp"

ENV FTP_DIR=/var/ivory \
    FTP_USER=ivory \
    FTP_PASS=ivory

COPY help.md /tmp/
RUN mkdir -p /licenses
COPY licenses /licenses

#Adding EPEL Repo for software - pure-ftpd
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

#Adding/intalling Pure-ftpd to the container
RUN yum -y install pure-ftpd

### Add necessary Red Hat repos here
RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms && \
### Add your package needs here
    yum -y update-minimal --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs \
--security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs \
      pure-ftpd golang-github-cpuguy83-go-md2man && \
### help file markdown to man conversion
    go-md2man -in /tmp/help.md -out /help.1 && rm -f /tmp/help.md && \
    yum clean all

RUN useradd -r ${FTP_USER} && \
    echo ${FTP_USER}:${FTP_PASS} | chpasswd -c SHA512 && \
    mkdir -p ${FTP_DIR} && \
    chown -R ${FTP_USER} ${FTP_DIR}

EXPOSE 21 30000-30009
VOLUME ${FTP_DIR}
CMD pure-ftpd -c 50 -C 10 -l unix -E -j -R -P ${PUBLICHOST} -p 30000:30009
