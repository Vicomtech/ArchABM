.. archABM documentation master file, created by
   sphinx-quickstart on Mon Jun 28 18:23:50 2021.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.


.. figure:: _static/logo_4.png
   :width: 400
   :align: center

   Agent-based model simulation for air quality and pandemic risk assessment in architectural spaces.

   `PyPI <https://pypi.python.org/pypi/simpy>`_ |
   `GitHub <https://github.com/VicomtechV3/ArchABM>`_ |
   `Issues <https://github.com/VicomtechV3/ArchABM/issues>`_

.. _user-guide:

User Guide
==========

``archABM`` is an agent-based model simulator for air quality and pandemic risk assessment in architectural spaces.

This documentation contains :ref:`a quick-start guide <user-guide>` (including
:ref:`installation<installation>` procedure and
:ref:`basic usage<basic-example>` of the simulator),
a complete :ref:`API Reference <api-reference>`, as well as a
gallery of :ref:`examples <examples>`.

Finally, if you use ``archABM`` in a scientific publication, we would appreciate :ref:`citations<citing>`.



.. _basic-example:

Basic Example
-------------

.. code-block:: python

   python main.py

Configuration parameters
^^^^^^^^^^^^^^^^^^^^^^^^

.. literalinclude:: ../../data/config_basic.json
    :language: JSON


Installation
------------

The first step to using any software package is getting it properly installed.
This part of the documentation covers the installation of ``archABM``. 

Using PyPI
^^^^^^^^^^

As the compiled ``archABM`` package is hosted on the Python Package Index (PyPI) you can easily install it with ``pip``.
To install ``archABM``, run this command in your terminal of choice:

.. code:: shell

    $ python -m pip install archABM

or, alternatively:

.. code:: shell

    $ pip install archABM


Using latest github-hosted version
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you want to get ``archABM``'s latest version, you can refer to the
repository hosted at github:

.. code-block:: bash

    python -m pip install https://github.com/VicomtechV3/ArchABM/archive/main.zip


Requirements
^^^^^^^^^^^^

``archABM`` builds on (and hence depends on) ``simpy``, ``tqdm`` and
``jsonschema`` libraries.



Source Code
-----------

archABM is developed on GitHub, where the code is
`always available <https://github.com/VicomtechV3/ArchABM>`_.

You can either clone the public repository::

    $ git clone git://github.com/VicomtechV3/ArchABM.git

Or, download the `tarball <https://github.com/VicomtechV3/ArchABM/tarball/main>`_::

    $ curl -OL https://github.com/VicomtechV3/ArchABM/tarball/main
    # optionally, zipball is also available (for Windows users).

Once you have a copy of the source, you can embed it in your own Python
package, or install it into your site-packages easily::

    $ cd ArchABM
    $ python -m pip install .


License
-------

.. literalinclude:: ../../LICENSE