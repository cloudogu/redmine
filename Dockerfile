# registry.cloudogu.com/official/redmine
FROM registry.cloudogu.com/official/base:3.9.4-1

LABEL NAME="official/redmine" \
   VERSION="3.4.11-1" \
   maintainer="robert.auer@cloudogu.com"

# This Dockerfile is based on https://github.com/docker-library/redmine/blob/master/4.0/alpine/Dockerfile

# set environment variables
ENV REDMINE_VERSION=4.0.5 \
    CAS_PLUGIN_VERSION=1.2.14 \
    ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION=0.1.0 \
    RUBYCASVERSION=2.3.14 \
    USER=redmine \
    BASEDIR=/usr/share/webapps \
    WORKDIR=/usr/share/webapps/redmine \
    SERVICE_TAGS=webapp \
    RAILS_ENV=production \
    REDMINE_TARGZ_MD5=d25649272a9c347e4368cdd50e039e86 \
    RAILS_RELATIVE_URL_ROOT=/redmine

# copy resource files
COPY resources/ /

# install theme, before the ownership is changed
ADD packages/cloudogu.tar.gz ${WORKDIR}/public/themes

RUN set -eux -o pipefail \
 # add user and group
 && addgroup -S "${USER}" -g 1000 \
 && adduser -S -h "${WORKDIR}" -G "${USER}" -u 1000 -s /bin/bash "${USER}" \
 # install runtime packages
 && apk --no-cache add --virtual /.run-deps \
   postgresql-client \
   sqlite-libs \
   imagemagick6 \
   imagemagick \
   tzdata \
   ruby \
   ruby-bigdecimal \
   ruby-bundler \
   ruby-rdoc \
   ruby-webrick \
   tini \
   libffi \
   su-exec \
   git \
 # install build dependencies
 && apk --no-cache add --virtual /.build-deps \
   build-base \
   ruby-dev \
   libxslt-dev \
   imagemagick6-dev \
   postgresql-dev \
   sqlite-dev \
   linux-headers \
   patch \
   coreutils \
   libffi-dev \
 # update ruby gems
 && echo 'gem: --no-document' > /etc/gemrc \
 && 2>/dev/null 1>&2 gem update --system --quiet \
 # install redmine
 && mkdir -p ${WORKDIR} \
 && wget -O redmine.tar.gz "https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" \
 && echo "${REDMINE_TARGZ_MD5} *redmine.tar.gz" | md5sum -c - \
 && tar -xf redmine.tar.gz --strip-components=1 -C ${WORKDIR} \
 && rm redmine.tar.gz \
 && mkdir -p ${WORKDIR}/app/assets/config && touch ${WORKDIR}/app/assets/config/manifest.js \
 # set temporary database configuration for bundle install
 && DATABASE_TYPE=postgresql \
    DATABASE_IP=localhost \
    DATABASE_DB=redmine \
    DATABASE_USER=redmine \
    DATABASE_USER_PASSWORD=redmine \
    eval "echo \"$(cat  ${WORKDIR}/config/database.yml.tpl)\"" > ${WORKDIR}/config/database.yml \
 # Install (available) rubycas-client version
 && git clone https://github.com/cloudogu/rubycas-client.git \
 && cd rubycas-client \
 && gem build rubycas-client.gemspec \
 && gem install rubycas-client-${RUBYCASVERSION}.gem \
 && cd .. \
 && rm -rf rubycas-client \
 # install redmine required gems
 && echo 'gem "activerecord-session_store"' >> ${WORKDIR}/Gemfile \
 # json gem missing in default installation?
 && echo 'gem "json"' >> ${WORKDIR}/Gemfile \
 # install required gems
 && cd ${WORKDIR} \
 && bundle install --without development test \
 # override environment to run redmine with a context path "/redmine"
 && mv ${WORKDIR}/config/environment.ces.rb ${WORKDIR}/config/environment.rb \
 # install core plugins
 && mkdir -p "${WORKDIR}/plugins" \
 # install cas plugin
 && mkdir "${WORKDIR}/plugins/redmine_cas" \
 && curl -sL \
    https://github.com/cloudogu/redmine_cas/archive/v${CAS_PLUGIN_VERSION}.tar.gz \
  | tar xfz - --strip-components=1 -C "${WORKDIR}/plugins/redmine_cas" \
 # install redmine_activerecord_session_store to be able to invalidate sessions after cas logout
 && mkdir "${WORKDIR}/plugins/redmine_activerecord_session_store" \
 && curl -sL \
    https://github.com/cloudogu/redmine_activerecord_session_store/archive/v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz \
  | tar xfz - --strip-components=1 -C "${WORKDIR}/plugins/redmine_activerecord_session_store" \
 # install plugin gems
 && cd ${WORKDIR} \
 && bundle install --without development test \
 # cleanup
 && gem cleanup all \
 && rm -rf /root/* /tmp/* $(gem env gemdir)/cache \
 && apk --purge del /.build-deps \
 && rm -rf /var/cache/apk/*

# set workdir
WORKDIR ${WORKDIR}

# expose application port
EXPOSE 3000

HEALTHCHECK CMD [ $(doguctl healthy redmine; echo $?) == 0 ]

# start
CMD /startup.sh
