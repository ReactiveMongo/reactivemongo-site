# Build:
#
#     docker build --build-arg sbt_version=1.6.2 -t cchantep/reactivemongo-site -f circleci.dockerfile .

# Push:
#
#     docker push cchantep/reactivemongo-site

FROM circleci/ruby:2.5-node-browsers

ARG sbt_version=1.6.2

COPY .ci_scripts/beforeInstall.sh /
COPY Gemfile /

USER root

RUN wget https://bootstrap.pypa.io/get-pip.py && \
python3.7 get-pip.py --user && \
chmod u+x beforeInstall.sh && \
./beforeInstall.sh ${sbt_version}

# For PDF generation
RUN sudo apt-get update -y && \
sudo apt-get install pandoc texlive-xetex fonts-inconsolata
