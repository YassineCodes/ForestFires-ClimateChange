## WHAT IS IT 

This model is a new version of the climate change model (Tinker, R. and Wilensky, U. (2007). NetLogo Climate Change model) and (Baghoussi, Y. Campos, P. and Rossetti, R., "An agent-based model of the Earth system & climate change").

The goal behind this project is to provide a test-bed that can be used by educators and also policy makers, so they can evaluate theories related to the Earth system so as to test and evaluate metrics such as greenhouse gases, forest fires and climate change in general. 


## HOW IT WORKS

The structure of the model is based on many climate theories which allow the user to run multiple scenarios. The scenarios are defined by multiple inputs set by the user after the environment modeling is concluded. While modeling an environment scenario, the user is able to set up the following parameters:

Landscape : Two types of landscapes are now available: field and desert. The field landscape is set by default and contains three types of landscapes: sea, field and icy grounds. The second landscape is desert. Selected to illustrate the effect of climate change at a regional scale. The Earth behaves as a system in which oceans, atmosphere and land, and the living and non-living parts therein, are all connected.

Sun Brightness: A value of "1" corresponds to the current position of the sun. Higher values would allow us to see what would happen if the Earth was closer to the sun in its orbit, or if the sun got brighter. Climate is influenced by natural changes that affect the amount of the solar energy that reaches the Earth.

Dynamic Albedo: Each landscape absorbs the sun energy in a different and specific way. The sea absorbs 100% of incoming energy; the ground absorbs from 50% to 60%; however, ice reflects all the incoming energy. That is to say it avoids warming.
The model is developed to automatically detect the type of the land (ground, icy, or sea) for the reflectiveness process.
The blue rays are the reflected incoming energy from the green land according to the rule of 50% to 60% of absorption.

Earth System: The equilibrium between the entering energy (yellow rays) and the leaving energy (purple rays) from the planet system relies on the Earth's temperature.
The Earth becomes warmer if its system absorbs the external incoming energy from sunlight. However, when solar energy is reflected due to clouds, the planet is no more warmer and the sunlight is reflected back to space (red rays). In addition, the Earth becomes colder when the absorbed energy is released into space (purple rays).

Trees Density: In the implemented simulation, the user is able to set a number of trees directly using the slider or simply by clicking a button to add trees. The correlation between the presence of trees and global temperature is significant.

Greenhouse Gases: The CO2, is the most abundant gas emitted by human activities alone provides 1/3 of the greenhouse effect. In this model, the amount  of CO2 added is proportional to the factories CO2 emission (75%) as well as the number of vehicles (25%).

Population: The CH4 is emitted after 300 walking steps of each person.
Natural rain fall: during the simulation the user can enable rain fall

Fire intensity: manual

wind velocity: both auto and manual

relative humidity: both auto and manual

The rain intensity: manual


## HOW TO USE IT

We propose some scenarios for demonstration:

Note: the user can use either buttons or sliders to tune the scenarios.

Global warming:

Scenario 1 - We propose a scenario which represents the desired world, a world without any CO2 emitter, with no climate change effect. The model contains simply an amount of people and trees.

Scenario 2 - The second scenario is a balance between carbon emitters and the number of trees. A moderate number of factories and cars/buses. (This scenario is tested after a new setup of the model)

The user can stop the sun, from the scenario 2, using the appropriate button and pursue with the following scenarios: 

Scenario 3 - Here, trees are removed (from the second scenario) and the factories, cars and buses are kept. This demonstrate the impact of removing the trees in the global temperature.

Scenario 4 - Trees are added back to the model. This will decrease the global temperature.

Results discussion of scenario 1:4 can be found in:
"An agent-based model of the Earth system & climate change" in ISC Smart Cities Conference IEEE International 2016.

Forest fires:

Scenario 1 - We run the model with 75% of fire intensity on a world without CO2 emitters

Scenario 2 - We run the model with 75% of fire intensity on a world with CO2 emitters.

Scenario 3 - We enable the natural rain fall during one of the above scenarios.

The results of Scenario 1:2 will demonstrate how the global warming affects the behavior of forest fire.

In scenario 3, the rain will cools off the burnt trees.

## THINGS TO NOTICE

Watch the reflected sun rays. In the sea, the sun energy is absorbed by 100%, in green land by around 50-60% and finally, in the icy land, it is reflected by 100%. 

The fire propagation is happening based on wind direction.
The fire propagates faster when Relative humidity is low and Wind velocity is high.

## THINGS TO TRY

1. Run the model with a desired parameters and stop the sun somewhere in the world than start adding, removing trees, factories, vehicles, people. Observe the temperature evolution, fire propagation and Wind / Relative humidity corelation.
2. Save the results in CSV file for further analysis and plots.
3. You can do more with your creativity =)

## NETLOGO FEATURES
Note that the background is a picture that is converted to patch colors.
Note that the land type is detected by checking the patch color of the background figure.
The C02 and CH4 do not leave the earth box. This is made using xcor and ycor.
Note that clouds are actually made up of lots of small circular turtles.

## RELATED MODELS
Tinker, R. and Wilensky, U. (2007). NetLogo Climate Change model

Baghoussi, Y. Campos, P. and Rossetti, R., "An agent-based model of the Earth system & climate change"

## CREDITS AND REFERENCES

This new model builds on an earlier version created in 2016 by Yassine Baghoussi for the Smart Cities Conference (ISC2), 2016 IEEE International.

## SOFTWARE

NetLogo software 6.0.3

https://ccl.northwestern.edu/netlogo

## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Y. Baghoussi, P. J. R. M. Campos and R. J. F. Rossetti, "An agent-based model of the Earth system & climate change," 2016 IEEE International Smart Cities Conference (ISC2), Trento, 2016, pp. 1-6.

## COPYRIGHT AND LICENSE

Copyright 2018 University of Porto.
