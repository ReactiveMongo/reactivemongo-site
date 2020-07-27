# Build:
#
#     docker build --build-arg sbt_version=1.3.13 -t cchantep/reactivemongo-site -f circleci.dockerfile .

# Push:
#
#     docker push cchantep/reactivemongo-site

FROM circleci/ruby:2.4-node-browsers

ARG sbt_version=1.3.13

COPY .ci_scripts/beforeInstall.sh /tmp/
COPY Gemfile /tmp/

USER root
RUN cd /tmp && \
wget https://bootstrap.pypa.io/get-pip.py && \
python get-pip.py --user && \
chmod u+x beforeInstall.sh && \
./beforeInstall.sh ${sbt_version}
