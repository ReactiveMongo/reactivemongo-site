# Build:
#
#     docker build --build-arg sbt_version=1.10.1 -t cchantep/reactivemongo-site -f circleci.dockerfile .

# Push:
#
#     docker push cchantep/reactivemongo-site

FROM cimg/ruby:3.3.6-node

ARG sbt_version=1.10.1

COPY .ci_scripts/beforeInstall.sh /home/circleci/
COPY Gemfile Gemfile.lock /home/circleci/

USER root

# For PDF generation
RUN sudo apt update -y && sudo apt upgrade -y && \
sudo apt-get install -y python3-distutils pandoc texlive-xetex fonts-inconsolata openjdk-11-jdk && \
wget https://bootstrap.pypa.io/get-pip.py && \
python3.10 get-pip.py --user && \
rm -f get-pip.py && \
cd /home/circleci && \
chown circleci beforeInstall.sh Gemfile Gemfile.lock && \
chmod a+x beforeInstall.sh

USER circleci
WORKDIR /home/circleci 

RUN ./beforeInstall.sh ${sbt_version}