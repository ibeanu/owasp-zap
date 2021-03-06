# This dockerfile builds the zap stable release
FROM ubuntu:16.04
LABEL maintainer="psiinon@gmail.com"

RUN apt-get update && apt-get install -q -y --fix-missing \
	make \
	automake \
	autoconf \
	gcc g++ \
	openjdk-8-jdk \
	ruby \
	wget \
	curl \
	xmlstarlet \
	unzip \
	git \
	openbox \
	xterm \
	net-tools \
	ruby-dev \
	python-pip \
	firefox \
	xvfb \
	x11vnc && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

RUN gem install zapr
RUN pip install --upgrade pip zapcli python-owasp-zap-v2.4

RUN useradd -d /home/zap -m -s /bin/bash zap
RUN echo zap:zap | chpasswd
RUN mkdir /zap && chown zap:zap /zap

WORKDIR /zap

#Change to the zap user so things get done as the right person (apart from copy)
USER zap

RUN mkdir /home/zap/.vnc

# Download and expand the latest stable release
RUN curl -s https://raw.githubusercontent.com/zaproxy/zap-admin/master/ZapVersions.xml | xmlstarlet sel -t -v //url |grep -i Linux | wget -nv --content-disposition -i - -O - | tar zxv && \
	cp -R ZAP*/* . &&  \
	rm -R ZAP* && \
	# Setup Webswing
	curl -s -L https://bitbucket.org/meszarv/webswing/downloads/webswing-2.5.5-distribution.zip > webswing.zip && \
	unzip webswing.zip && \
	rm webswing.zip && \
	mv webswing-* webswing && \
	# Remove Webswing demos
	rm -R webswing/demo/ && \
	# Accept ZAP license
	touch AcceptedLicense


ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
ENV PATH $JAVA_HOME/bin:/zap/:$PATH
ENV ZAP_PATH /zap/zap.sh

# Default port for use with zapcli
ENV ZAP_PORT 8080
ENV HOME /home/zap/

COPY zap* /zap/
COPY webswing.config /zap/webswing/
COPY policies /home/zap/.ZAP/policies/
COPY .xinitrc /home/zap/

#Copy doesn't respect USER directives so we need to chown and to do that we need to be root
USER root

RUN chown zap:root /zap/zap-x.sh && \
	chown zap:root /zap/zap-baseline.py && \
	chown zap:root /zap/zap-webswing.sh && \
	chown zap:root /zap/webswing/webswing.config && \
	chown -R zap:root /home/zap/.ZAP/ && \
	chown zap:root /home/zap/.xinitrc && \
	chown -R zap:root /zap && \
	mkdir -p /zap/?/.ZAP && \
	chmod -R g+wr /zap && \
	chown -R zap:root /home/zap && \
	chmod -R g+wr /home/zap && \
	chmod a+x /home/zap/.xinitrc

#Change back to zap at the end
USER zap

HEALTHCHECK --retries=5 --interval=5s CMD zap-cli status
