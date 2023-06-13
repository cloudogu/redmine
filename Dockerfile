# registry.cloudogu.com/official/redmine
FROM registry.cloudogu.com/official/base:3.17.3-2

LABEL NAME="official/redmine" \
   VERSION="4.2.9-4" \
   maintainer="hello@cloudogu.com"

ENV USER=redmine \
    BASEDIR=/usr/share/webapps \
    WORKDIR=/usr/share/webapps/redmine \
    SERVICE_TAGS=webapp \
    RAILS_ENV=production \
    RAILS_RELATIVE_URL_ROOT=/redmine \
    STARTUP_DIR=/ \
    # Rubycas-client version
    RUBYCASVERSION=2.4.0.rc1 \
    RUBYCAS_TARGZ_SHA256=c5b0dd09a77c02ce228f9d58735f6833bc5ab9a64ec0351899a447fcf0da26ec \
    # Redmine version
    REDMINE_VERSION=5.0.5 \
    REDMINE_TARGZ_SHA256=a89ad1c4bb9bf025e6527c77ab18c8faf7749c94a975caf2cfdbba00eb12a481 \
    REDMINE_PATH="/usr/share/webapps/redmine" \
    # Rest-API-Plugin version
    EXTENDED_REST_API_PLUGIN_VERSION=1.1.0 \
    EXTENDED_REST_API_TARGZ_SHA256=7def9dee6a72f7a98c34c3d0beb17dabd414a1af86153624eb03ffe631272b31 \
    EXTENDED_REST_API_PLUGIN_PATH="/usr/share/webapps/redmine/defaultPlugins/redmine_extended_rest_api" \
    # Activerecord session plugin version
    ACTIVERECORD_SESSION_STORE_PLUGIN_VERSION=0.2.0-rc2 \
    ACTIVERECORD_TARGZ_SHA256=a60dda982c99d28eebc7eaa7e56cd4b59eceef5227d843edb64388f07ad84cb4 \
    ACTIVERECORD_SESSION_STORE_PLUGIN_PATH="/usr/share/webapps/redmine/defaultPlugins/redmine_activerecord_session_store" \
    # CAS-Plugin version
    CAS_PLUGIN_VERSION=2.0.0.rc1 \
    CAS_PLUGIN_TARGZ_SHA256=5b8e33f183db8ae5ac3cc7029b0dce70c4550cefc30429c7139944489f6f2c7d \
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
   postgresql-client \
   sqlite-libs \
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
 && bundle config set --local without7 'development test' \
 && bundle install \
 && gem install puma \
 # cleanup
 && gem cleanup all \
 && rm -rf /root/* /tmp/* $(gem env gemdir)/cache \
 && apk --purge del /.build-deps \
 && rm -rf /var/cache/apk/* \
 && apk add ruby-irb

# set workdir
WORKDIR ${WORKDIR}

# expose application port
EXPOSE 3000

HEALTHCHECK --interval=5s CMD doguctl healthy redmine || exit 1

# start
CMD ["/startup.sh"]
