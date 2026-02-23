# MicroGPT - ABAP Port

MicroGPT is a minimalist, educational implementation of a Generative Pre-trained Transformer (GPT) language model, originally created by Andrej Karpathy. This repository contains a pure **ABAP** port of MicroGPT, designed to run natively within SAP systems.

It includes everything you need to train and run inference for a simple transformer model, built from scratch using object-oriented ABAP.

## Features

- **Custom Autograd Engine**: The `zcl_micro_gpt_value` class implements scalar-valued autograd with backpropagation, forming the core of the neural network's computations.
- **Transformer Architecture**: Complete implementation of a transformer language model:
  - Embeddings (`zcl_micro_gpt_embedding`)
  - Linear Layers (`zcl_micro_gpt_linear`)
  - Attention Mechanisms and Blocks (`zcl_micro_gpt_block`)
  - Layer Normalization (`zcl_micro_gpt_layers`)
  - Key-Value Caching (`zcl_micro_gpt_kv_cache`)
- **Training Setup**: Built-in Adam Optimizer (`zcl_micro_gpt_optim_adam`) and a Trainer class (`zcl_micro_gpt_trainer`) for training the model on your dataset.
- **Inference**: Generate text using the built-in Inference class (`zcl_micro_gpt_inference`).
- **Tokenizer & Dataset**: Simple custom tokenizer and dataset loaders for processing raw text.

## Installation

This project can be easily installed into your SAP system using [abapGit](https://abapgit.org/).

1. Open your SAP system and start the abapGit transaction (usually `ZABAPGIT`).
2. Click on **New Online** (or **New Offline** if you downloaded a ZIP).
3. Enter the repository URL.
4. Select a target package (e.g., `ZMICROGPT` or `$MICROGPT` for a local package).
5. Pull the code.

## Usage / Demo

To understand how the components tie together, check out the provided demo program: `zmicro_gpt_demo`.

The demo program illustrates:
1. Loading a dataset (e.g., `names.txt`).
2. Initializing the Tokenizer and Model architecture (embedding dimensions, heads, layers).
3. Initializing the Trainer with Adam Optimizer configurations.
4. Running the training loop.
5. Initiating an interactive prompt using `cl_demo_input` to generate text based on the trained model.

## License

This project is licensed under the MIT License - see the contents below for details.

```
MIT License

Copyright (c) 2026

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
