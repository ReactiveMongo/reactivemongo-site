# Build:
#
#     docker build --build-arg sbt_version=1.3.13 -t cchantep/reactivemongo -f circleci.dockerfile .

# Push:
#
#     docker push cchantep/reactivemongo

FROM circleci/ruby:2.4-node-browsers

ARG sbt_version=1.3.13

COPY .ci_scripts/beforeInstall.sh /
COPY Gemfile /

USER root

RUN wget https://bootstrap.pypa.io/get-pip.py && \
python get-pip.py --user && \
chmod u+x beforeInstall.sh && \
./beforeInstall.sh ${sbt_version}
