FROM registry.cloudogu.com/official/base:3.19.3-1

LABEL NAME="official/redmine" \
   VERSION="5.1.3-3" \
   maintainer="hello@cloudogu.com"

ENV USER=redmine \
    BASEDIR=/usr/share/webapps \
    WORKDIR=/usr/share/webapps/redmine \
    SERVICE_TAGS=webapp \
    RAILS_ENV=production \
    RAILS_RELATIVE_URL_ROOT=/redmine \
    STARTUP_DIR=/ \
    # Rubycas-client version
    RUBYCASVERSION=2.4.0 \
    RUBYCAS_TARGZ_SHA256=1fb29cf6a2331dc91b7cdca3d9b231866a4cfc36c4c5f03cedd89c74cc5aae05 \
    # Redmine version
    REDMINE_VERSION=5.1.3 \
    REDMINE_TARGZ_SHA256=8a22320fd9c940e6598f3ad5fb7a3933195c86068eee994ba6fcdc22c5cecb59 \
    REDMINE_PATH="/usr/share/webapps/redmine" \
    # Rest-API-Plugin version
    EXTENDED_REST_API_PLUGIN_VERSION=1.1.0 \
    EXTENDED_REST_API_TARGZ_SHA256=7def9dee6a72f7a98c34c3d0beb17dabd414a1af86153624eb03ffe631272b31 \
    EXTENDED_REST_API_PLUGIN_PATH="/usr/share/webapps/redmine/defaultPlugins/redmine_extended_rest_api" \
    # Activerecord session plugin version
    ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION=0.2.0 \
    ACTIVERECORD_TARGZ_SHA256=6e9bdeef6ddaef3b997251418647bd17b11bb10d36b7a2ad27f387cb511858ea \
    ACTIVERECORD_SESSION_STORE_PLUGIN_PATH="/usr/share/webapps/redmine/defaultPlugins/redmine_activerecord_session_store" \
    # CAS-Plugin version
    CAS_PLUGIN_VERSION=2.1.2 \
    CAS_PLUGIN_TARGZ_SHA256=0a0234fca4224aa3da47e60fb20f633a6a11f328dfdac11c33548bfbd6dd1baf \
    CAS_PLUGIN_PATH="/usr/share/webapps/redmine/defaultPlugins/redmine_cas" \
    # Cloudogu theme version
    CLOUDOGU_THEME_VERSION=2.15.0-2 \
    THEME_TARGZ_SHA256=bf3f96cecb8b030f0207fda60d69ac957f14327403819e1da4592ed6bbe99057 \
    CLOUDOGU_THEME_PATH="/usr/share/webapps/redmine/public/themes/Cloudogu"

COPY resources/ /

RUN set -eux -o pipefail \
 ## Install Redmine
 && mkdir -p ${REDMINE_PATH} \
 && mkdir -p /redmine_source \
 && wget "https://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" \
 && echo "${REDMINE_TARGZ_SHA256} *redmine-${REDMINE_VERSION}.tar.gz" | sha256sum -c - \
 && tar -xf redmine-${REDMINE_VERSION}.tar.gz --strip-components=1 -C ${REDMINE_PATH} \
 && mv redmine-${REDMINE_VERSION}.tar.gz /redmine_source/redmine-${REDMINE_VERSION}.tar.gz \
 && mkdir -p ${REDMINE_PATH}/app/assets/config && touch ${REDMINE_PATH}/app/assets/config/manifest.js \
 ## Install redmine_cas Plugin
 && mkdir -p "${CAS_PLUGIN_PATH}" \
 && wget -O v${CAS_PLUGIN_VERSION}.tar.gz "https://github.com/cloudogu/redmine_cas/archive/v${CAS_PLUGIN_VERSION}.tar.gz" \
 && echo "${CAS_PLUGIN_TARGZ_SHA256} *v${CAS_PLUGIN_VERSION}.tar.gz" | sha256sum -c - \
 && tar -C "${CAS_PLUGIN_PATH}" --strip-components=2 -zxf "v${CAS_PLUGIN_VERSION}.tar.gz" "redmine_cas-${CAS_PLUGIN_VERSION}/src" \
 && rm v${CAS_PLUGIN_VERSION}.tar.gz \
 ## Install Cloudogu Theme
 && mkdir -p "${CLOUDOGU_THEME_PATH}" \
 && wget -O v${CLOUDOGU_THEME_VERSION}.tar.gz "https://github.com/cloudogu/PurpleMine2/releases/download/v${CLOUDOGU_THEME_VERSION}/CloudoguRedmineTheme-${CLOUDOGU_THEME_VERSION}.tar.gz" \
 && echo "${THEME_TARGZ_SHA256} *v${CLOUDOGU_THEME_VERSION}.tar.gz" | sha256sum -c - \
 && tar xfz v${CLOUDOGU_THEME_VERSION}.tar.gz --strip-components=1 -C "${CLOUDOGU_THEME_PATH}" \
 && rm v${CLOUDOGU_THEME_VERSION}.tar.gz \
 ## Install Session-Store-Plugin \
 && mkdir -p "${ACTIVERECORD_SESSION_STORE_PLUGIN_PATH}" \
 && wget -O v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz "https://github.com/cloudogu/redmine_activerecord_session_store/archive/v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz" \
 && echo "${ACTIVERECORD_TARGZ_SHA256} *v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz" | sha256sum -c - \
 && tar xfz v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz --strip-components=1 -C "${ACTIVERECORD_SESSION_STORE_PLUGIN_PATH}" \
 && rm v${ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION}.tar.gz \
 ## Install extended_rest_api Plugin \
 && mkdir -p "${EXTENDED_REST_API_PLUGIN_PATH}" \
 && wget -O v${EXTENDED_REST_API_PLUGIN_VERSION}.tar.gz \
 "https://github.com/cloudogu/redmine_extended_rest_api/archive/v${EXTENDED_REST_API_PLUGIN_VERSION}.tar.gz" \
 && echo "${EXTENDED_REST_API_TARGZ_SHA256} *v${EXTENDED_REST_API_PLUGIN_VERSION}.tar.gz" | sha256sum -c - \
 && SUB_DIR="redmine_extended_rest_api-${EXTENDED_REST_API_PLUGIN_VERSION}/src/" \
 && tar -C "${EXTENDED_REST_API_PLUGIN_PATH}" --strip-components=2 -xvf v${EXTENDED_REST_API_PLUGIN_VERSION}.tar.gz "${SUB_DIR}" \
 && rm v${EXTENDED_REST_API_PLUGIN_VERSION}.tar.gz \
 && find "${EXTENDED_REST_API_PLUGIN_PATH}" -name 'Gemfile*' -type f -delete \
 && apk update \
 && apk upgrade \
 # add user and group
 && addgroup -S "${USER}" -g 1000 \
 && adduser -S -h "${WORKDIR}" -G "${USER}" -u 1000 -s /bin/bash "${USER}" \
 # install runtime packages
 && apk --no-cache add --virtual /.run-deps \
   postgresql16-client \
   imagemagick \
   tzdata \
   ruby \
   ruby-bundler \
   ruby-rdoc \
   tini \
   libffi \
   su-exec \
   git \
   curl \
 # install build dependencies
 && apk --no-cache add --virtual /.build-deps \
   build-base \
   ruby-dev \
   libxslt-dev \
   postgresql-dev \
   sqlite-dev \
   linux-headers \
   patch \
   coreutils \
   libffi-dev \
 # update ruby gems
 && echo 'gem: --no-document' > /etc/gemrc \
 && 2>/dev/null 1>&2 gem update --system --quiet \
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
 # json gem missing in default installation?
 && echo 'gem "json"' >> ${WORKDIR}/Gemfile \
 # override environment to run redmine with a context path "/redmine"
 && mv ${WORKDIR}/config/environment.ces.rb ${WORKDIR}/config/environment.rb \
 # install core plugins
 && mkdir -p "${WORKDIR}/plugins" \
 # install required and plugin gems \
 # copy the plugins to the plugin directory in order to gain all gems and gem checksums for machines without internet access
 && cp -r "${WORKDIR}"/defaultPlugins/* "${WORKDIR}/plugins/" \
 && cd ${WORKDIR} \
 && bundle config set --local without 'development test' \
 && bundle install \
 && gem install puma \
 # Do not remove the dependency on bigdecimal. Many tools rely on bigdecimal, and it may not be possible to install it in a running dogu
 && gem install bigdecimal -v 3.1.6 \
 && bundle add bigdecimal --version=3.1.6 \
 # cleanup
 && gem cleanup all \
 && rm -rf /root/* /tmp/* $(gem env gemdir)/cache \
 && apk --purge del /.build-deps \
 && rm -rf /var/cache/apk/* \
 && apk add ruby-irb

WORKDIR ${WORKDIR}

EXPOSE 3000

HEALTHCHECK --interval=5s CMD doguctl healthy redmine || exit 1

# start
CMD ["/startup.sh"]
