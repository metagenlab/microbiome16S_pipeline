## Install Ubuntu
FROM ubuntu:16.04

############################## Install miniconda environement, from miniconda3 Dockerfile ##############################
#  $ docker build . -t continuumio/miniconda3:latest -t continuumio/miniconda3:4.5.11
#  $ docker run --rm -it continuumio/miniconda3:latest /bin/bash
#  $ docker push continuumio/miniconda3:latest
#  $ docker push continuumio/miniconda3:4.5.11

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH
ENV TZ Europe/Zurich

RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-4.6.14-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -tipsy && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc

ENV TINI_VERSION v0.16.1
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini


############################## Create USER ##############################
RUN useradd -r -u 1080 pipeline_user

RUN conda config --add channels defaults && conda config --add channels conda-forge && conda config --add channels bioconda

############################## Install Snakemake ##############################
RUN conda install snakemake=5.5.0

############################## r-v8 dependancy, r-v8 and randomcoloR R package #######################
## libv8
RUN apt-get update && apt-get -y install libv8-dev libcurl4-openssl-dev
## R-v8
RUN conda install -c dloewenstein r-v8

## randomcoloR
### Dependencies
RUN Rscript -e "install.packages('randomcoloR')"

#RUN wget https://cran.r-project.org/src/contrib/randomcoloR_1.1.0.tar.gz -O /tmp/randomcoloR.tar.gz
#RUN R CMD INSTALL /tmp/randomcoloR.tar.gz -l /opt/conda/lib/R/library/

### Clone github
ARG GITHUB_AT
RUN git clone --single-branch --branch dev https://$GITHUB_AT@github.com/metagenlab/microbiome16S_pipeline.git

### Create all environments of the pipeline
RUN snakemake microbiome16S_pipeline/Snakefile --use-conda --conda-prexifx /opt/conda/ --create-envs-only

#ENTRYPOINT [ "/bin/bash", "source activate r_visualization" ]

RUN chown -R pipeline_user ${main}/

USER pipeline_user

WORKDIR ${main}/data/analysis/
