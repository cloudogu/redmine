# registry.cloudogu.com/official/redmine
FROM registry.cloudogu.com/official/base:3.9.4-2

LABEL NAME="official/redmine" \
   VERSION="4.1.0-1" \
   maintainer="robert.auer@cloudogu.com"

# This Dockerfile is based on https://github.com/docker-library/redmine/blob/master/4.0/alpine/Dockerfile

# set environment variables
ENV REDMINE_VERSION=4.1.0 \
    CAS_PLUGIN_VERSION=1.2.14 \
    ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION=0.1.0 \
    RUBYCASVERSION=2.3.15 \
    USER=redmine \
    BASEDIR=/usr/share/webapps \
    WORKDIR=/usr/share/webapps/redmine \
    SERVICE_TAGS=webapp \
    RAILS_ENV=production \
    REDMINE_TARGZ_SHA256=91f220504ee0d25ea0f8ed4d6cc49071c914b6de616cf488dc8e91427107acbb \
    CAS_PLUGIN_TARGZ_SHA256=184cbb41abde38e85aae1f4f0117adf2f1eff061ccfe377c91c3545428c5ad46 \
    ACTIVERECORD_TARGZ_SHA256=a5d3a5ac6c5329212621bab128a2f94b0ad6bb59084f3cc714786a297bcdc7ee \
    RUBYCAS_TARGZ_SHA256=9ca9b2e020c4f12c3c7e87565b9aa19dda130912138d80ad6775e5bdc2d4ca66 \
    RAILS_RELATIVE_URL_ROOT=/redmine \
    CLOUDOGU_THEME_VERSION=2.8.0-2 \
    THEME_TARGZ_SHA256=9c9078f52fffbadc140f67001702dd894cf3e6f537fa2f27e7746ca608a9bf77

# copy resource files
COPY resources/ /

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
 && mkdir -p /redmine_source \
 && wget "https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" \
 && echo "${REDMINE_TARGZ_SHA256} *redmine-${REDMINE_VERSION}.tar.gz" | sha256sum -c - \
 && tar -xf redmine-${REDMINE_VERSION}.tar.gz --strip-components=1 -C ${WORKDIR} \
 && mv redmine-${REDMINE_VERSION}.tar.gz /redmine_source/redmine-${REDMINE_VERSION}.tar.gz \
 && mkdir -p ${WORKDIR}/app/assets/config && touch ${WORKDIR}/app/assets/config/manifest.js \
 # set temporary database configuration for bundle install
 && cp ${WORKDIR}/config/database.yml.tpl ${WORKDIR}/config/database.yml \
 # Install rubycas-client
 && wget -O v${RUBYCASVERSION}.tar.gz "https://github.com/cloudogu/rubycas-client/archive/v${RUBYCASVERSION}.tar.gz" \
 && echo "${RUBYCAS_TARGZ_SHA256} *v${RUBYCASVERSION}.tar.gz" | sha256sum -c - \
 && mkdir rubycas-client \
 && tar xfz v${RUBYCASVERSION}.tar.gz --strip-components=1 -C rubycas-client \
 && rm v${RUBYCASVERSION}.tar.gz \
 && cd rubycas-client \
 && gem build rubycas-client.gemspec \
 && gem install rubycas-client-${RUBYCASVERSION}.gem \
 && cd .. \
 && rm -rf rubycas-client \
 # install redmine required gems
 && echo 'gem "activerecord-session_store"' >> ${WORKDIR}/Gemfile \
 # json gem missing in default installation?
 && echo 'gem "json"' >> ${WORKDIR}/Gemfile \
 # override environment to run redmine with a context path "/redmine"
 && mv ${WORKDIR}/config/environment.ces.rb ${WORKDIR}/config/environment.rb \
 # install core plugins
 && mkdir -p "${WORKDIR}/plugins" \
 # install cas plugin
 && mkdir "${WORKDIR}/plugins/redmine_cas" \
 && wget -O v${CAS_PLUGIN_VERSION}.tar.gz "https://github.com/cloudogu/redmine_cas/archive/v${CAS_PLUGIN_VERSION}.tar.gz" \
 && echo "${CAS_PLUGIN_TARGZ_SHA256} *v${CAS_PLUGIN_VERSION}.tar.gz" | sha256sum -c - \
 && tar xfz v${CAS_PLUGIN_VERSION}.tar.gz --strip-components=1 -C "${WORKDIR}/plugins/redmine_cas" \
 && rm v${CAS_PLUGIN_VERSION}.tar.gz \
 # install Cloudogu theme
 && mkdir -p "${WORKDIR}/public/themes/Cloudogu" \
 && wget -O v${CLOUDOGU_THEME_VERSION}.tar.gz "https://github.com/cloudogu/PurpleMine2/releases/download/v${CLOUDOGU_THEME_VERSION}/CloudoguRedmineTheme-${CLOUDOGU_THEME_VERSION}.tar.gz" \
 && echo "${THEME_TARGZ_SHA256} *v${CLOUDOGU_THEME_VERSION}.tar.gz" | sha256sum -c - \
 && tar xfz v${CLOUDOGU_THEME_VERSION}.tar.gz --strip-components=1 -C "${WORKDIR}/public/themes/Cloudogu" \
 && rm v${CLOUDOGU_THEME_VERSION}.tar.gz \
 # install redmine_activerecord_session_store to be able to invalidate sessions after cas logout
 && mkdir "${WORKDIR}/plugins/redmine_activerecord_session_store" \
 && wget -O v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz "https://github.com/cloudogu/redmine_activerecord_session_store/archive/v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz" \
 && echo "${ACTIVERECORD_TARGZ_SHA256} *v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz" | sha256sum -c - \
 && tar xfz v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz --strip-components=1 -C "${WORKDIR}/plugins/redmine_activerecord_session_store" \
 && rm v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz \
 # install required and plugin gems
 && cd ${WORKDIR} \
 && bundle install --without development test \
 && gem install puma \
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
CMD ["/startup.sh"]
