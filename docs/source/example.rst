.. example:

Example
=======

Input Configuration
-------------------

In this example, the simulated configuration is based on the real floor plan of a research center. The floor plan is only shown for illustration purposes and is not required to run the simulator. As explained in the :ref:`Components` section, the simulator only requires information about the types of *events* that can occur, *places*' spatial parameters (area & capacity), the number of *people* initially present and the *aerosol model* physical parameters. 

.. figure:: _static/figures/floorplan.png
    :align: center
    :width: 600
    :name: floorplan

    Figure 1: Building floor plan used in the example

Events
^^^^^^

The events' parameters are summarized in :ref:`table_3`. There are five types of events: *work, meeting, coffee, restroom*, and *lunch*. Meetings and lunch activities are regarded as collective events. Each event model is limited to a certain schedule, duration :math:`\tau`, and a number of repetitions. For each event model, the mask efficiency :math:`m_e` is also defined (not used anywhere :math:`m_e=0`).

.. figure:: _static/figures/table_3.png
    :align: center
    :width: 600
    :name: table_3

    Table 1: Events parameters

Places
^^^^^^

Places' parameters are summarized in :ref:`table_4`. The floor area of each location is measured, and the volume :math:`V` is estimated assuming a height of 2.7 m. The initial number of people present :math:`N`, the maximum number of people that can fit in the room, and the ventilation rates (both active :math:`\lambda_r` and passive :math:`\lambda_a`) are also defined. Meeting rooms A, B, C, and restrooms A and B are subject to poor passive ventilation, as they are oriented towards the interior of the building and do not have direct access to a window. A low passive ventilation rate is established (:math:`\lambda_a=1.5`, and :math:`\lambda_a=0.5` for poor ventilated rooms) and there is no active ventilation (:math:`\lambda_r=0$). 

.. figure:: _static/figures/table_4.png
    :align: center
    :width: 750
    :name: table_4

    Table 2: Places parameters

People
^^^^^^

There are 60 people distributed in 7 different departments: D1, D2, and D3 have 16 people each; D4 refers to 7 IT workers, and D5, D6, D7 hold the head of departments, with 2, 2, and 1 people respectively. The number of infected people :math:`N_i` is set to 3 in all the proposed scenarios. 

Aerosol Model
^^^^^^^^^^^^^

The aerosol model presented by Peng and Jimenez :cite:`doi:10.1021/acs.estlett.1c00183,https://doi.org/10.1111/ina.12751,Peng2021.04.21.21255898`. derives analytical expressions of CO\ :sub:`2` based risk proxies, assuming the social distance is maintained. The relative infection risk in a given environment scales with excess CO\ :sub:`2` level, and thus, keeping CO\ :sub:`2` as low as possible is essential to reducing the likelihood of infection. This model calculates both the virus quanta concentration and the CO\ :sub:`2` mixing ratio present in a specific place. These two metrics provide an overall picture of indoor air quality, which is why this model was selected for ArchABM.

The aerosol model considers some parameters to be constant across the entire building, as shown in :ref:`table_1`. These constant values, breathing or virus related, are based on the study undertaken by Peng and Jimenez. On the contrary, certain parameters are specified for each place, such as volume, ventilation, or the number of people present, as shown in :ref:`table_2`.

.. figure:: _static/figures/table_1.png
    :align: center
    :width: 600
    :name: table_1

    Table 3: Aerosol model constant parameters

.. figure:: _static/figures/table_2.png
    :align: center
    :width: 375
    :name: table_2

    Table 4: Aerosol model variable parameters

Generated config.json
^^^^^^^^^^^^^^^^^^^^^

.. raw:: html

    <details>
    <summary><a>config.json</a></summary>

.. literalinclude:: ../../data/config.json
    :language: JSON

.. raw:: html
    
    </details>

|

Output Results
--------------

Regarding ArchABM's output, whenever a new event occurs, the simulator saves the state of each person and each place in the simulation history data structure. 


Raw results
^^^^^^^^^^^

* ``people.csv`` stores every person's state along time.

.. csv-table::
   :file: ../../results/people_example.csv
   :header-rows: 1
   :align: center

* ``places.csv`` stores every places's state along time.

.. csv-table::
   :file: ../../results/places_example.csv
   :header-rows: 1
   :align: center

Visualization
^^^^^^^^^^^^^

People metrics
""""""""""""""

:ref:`fig_8a` summarizes the types of events (coffee, lunch, meetings, go to the restroom, do office work) performed by all occupants throughout the day, while :ref:`fig_8b` shows a detailed breakdown of the activities performed by each person throughout the day. 

.. figure:: _static/figures/timeline_activity_density.png
    :align: center
    :width: 550
    :name: fig_8a

    Figure 2: Activity density distribution

Agents are strictly adhering to the specified schedule, with two coffee breaks, one main lunch event, and meetings, restrooms, and work events spread throughout the day. The three randomly infected people are also highlighted in :ref:`fig_8b`.

.. figure:: _static/figures/timeline_activity_person.png
    :align: center
    :width: 550
    :name: fig_8b

    Figure 3: Activities performed by each person

The amount of quanta inhaled per person is depicted in :ref:`fig_8c`. Each line represents a person, and the red dotted lines indicate the three infected people. The color of the line represents the activity that each agent is performing. For instance, meetings and lunch activities primarily contribute to quanta inhalation between the agents. 

.. figure:: _static/figures/timeline_person_quanta.png
    :align: center
    :width: 550
    :name: fig_8c

    Figure 4: Quanta inhaled per person


The total quanta inhaled by each person at the end of the day is shown in :ref:`fig_8d`, and the three infected people are highlighted with red dots.

.. figure:: _static/figures/distribution_person_quanta.png
    :align: center
    :width: 550
    :name: fig_8d

    Figure 5: Quanta inhaled by each person at the end of the day



Places metrics
""""""""""""""

From the places perspective, archABM also offers the possibility of tracking the CO\ :sub:`2` and *quanta* concentration levels. 
Examining the CO\ :sub:`2` level at each place throughout the day (:ref:`fig_9a`), it can be observed that the meeting rooms accumulate the highest CO\ :sub:`2` concentration throughout the day. The coffee places rapidly accumulate CO\ :sub:`2` during the coffee events, but the air quality is restored between the coffee breaks. Other rooms, for example, restrooms and office places show a more constant CO\ :sub:`2` level. 


.. figure:: _static/figures/timeline_place_CO2.png
    :align: center
    :width: 550
    :name: fig_9a

    Figure 6: CO\ :sub:`2` level at each place

The distribution of CO\ :sub:`2` concentration can directly be observed in :ref:`fig_9b`, where a box-plot is overlaid on top of a violin plot. 

.. figure:: _static/figures/boxplot_place_CO2.png
    :align: center
    :width: 700
    :name: fig_9b

    Figure 7: CO\ :sub:`2` level distribution at each place

A similar interpretation can be concluded with the *quanta* concentration for this simulation run, as shown in :ref:`fig_9c` and :ref:`fig_9d`.

.. figure:: _static/figures/timeline_place_quanta.png
    :align: center
    :width: 550
    :name: fig_9c

    Figure 8: quanta level at each place

.. figure:: _static/figures/boxplot_place_quanta.png
    :align: center
    :width: 700
    :name: fig_9d

    Figure 9: quanta level distribution at each place

Metrics related to indoor air quality at the place level have been overlaid on the floor plan, as shown in :ref:`floorplan_CO2` and :ref:`floorplan_quanta`. Concerning the CO\ :sub:`2` level, meeting rooms are highlighted as the worst locations. With regard to the *quanta* level, meeting rooms B and C come out worst in this case. 
These results demonstrate archABM's capabilities of detecting "hotspots" in terms of high CO\ :sub:`2` and virus quanta concentrations (in our case meeting rooms and the coffee place) across the entire building.



.. figure:: _static/figures/floorplan_CO2.png
    :align: center
    :width: 600
    :name: floorplan_CO2

    Figure 10: Maximum CO\ :sub:`2` level at each place


.. figure:: _static/figures/floorplan_quanta.png
    :align: center
    :width: 600
    :name: floorplan_quanta

    Figure 11: Maximum quanta level at each place


.. note::
    
    It should be noted that the results in this section refer to a single simulation run and that the *quanta*-related metrics are very dependent on the randomly selected infected people. However, the high computational performance of archABM allows running multiple simulations and carry out robust statistical analysis.