# MBARI-RetinaNet-ODM

This repo contains the Python and shell scripts pipeline to prepare data and train the GCP RetinaNet TPU model on the cloud for MBARI's Station M Images. All scripts run relative to our given data set. If you are using a different dataset, much of this repository won't work, but the primary methodology will still apply. This README will address these differences and what one might change in order to use a separate dataset. 

###### Authors

* Andrea Cano
* Sampson Liao
* Austin Martinez
* Kirk Worley

## Install
##### Base Installation 
* Download and install the latest version of docker [Docker](https://www.docker.com/)
* Download and install [Python 3](https://www.python.org/download/releases/3.0/).
* Install Tensorflow Docker image using `docker pull tensorflow/tensorflow`
* Run a `git pull` on this repository

##### CVAT 
Part of this project was setting up and configuring CVAT to label images. If you are attempting to install CVAT we have written some documentation on how to do so [here](https://docs.google.com/document/d/1277nbsISsqZBLsdxFQCm6-fhEhYLTtJpRFNCSxvR40I/edit?usp=sharing).

## Preparing the data

The primary operation of the `Dockerfile`, is to run `create_tfrecord.py`. The RetinaNet TPU accepts Tensorflow Records (tfrecords) for training/testing data input. We have not been able to successfully train the model using file types other than tfrecords. [Tutorials and documentation](https://cloud.google.com/tpu/docs/tutorials/retinanet) for RetinaNet operate under the assumption that you have properly formatted and saved tfrecords. 

The `create_tfrecord.py` file generates tfrecords specific to our Station M data. If you are looking to use custom data, you must construct tfrecords that adhere to it. We do not recommend an alteration of either the `Dockerfile` or the `create_tfrecords.py` file, as both adhere strictly to the file structure of our given data. Custom data will require a custom solution to generate tfrecords. You do not necessarily need to use Docker, for instance. 

[Here](https://medium.com/mostly-ai/tensorflow-records-what-they-are-and-how-to-use-them-c46bc4bbb564) is a helpful tutorial for understanding tfrecords.

##### Remove Non-numeric Characters from files

Something important not mentioned by GCP, is that the names of your images must **only** consist of numbers, and the file extension must be removed before creating tfrecords. If you run into an error when training on the cloud that looks something like:
```
Error recorded from infeed: StringToNumberOp could not norrectly convert string
```
you need to remove all non-numeric characters from your images before you create tfrecords. Which, in our case, is before using the `Dockerfile` that runs `create_tfrecord.py`. 


# soemthing something talk about how we have a script to fix this but that it only works for our specific data structure (protobufs and annotations.xml and stuff)

* Build Docker image with preprocess tag using `docker build -t preprocess .`
* Ensure proper permissions, then run `./train_test.sh`