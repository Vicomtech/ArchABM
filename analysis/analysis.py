# %%
import os
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

# %%

path = "../results"
experiments = os.listdir(path)
experiments.sort()
experiment = experiments[-1]
print(experiment)

config_file = os.path.join(path, experiment, "config.json")
places_file = os.path.join(path, experiment, "places.csv")
people_file = os.path.join(path, experiment, "people.csv")

config = json.load(open(config_file))
places = pd.read_csv(places_file)
people = pd.read_csv(people_file)

places_info = pd.DataFrame(config["Places"])
people_info = pd.DataFrame(config["People"])
events_info = pd.DataFrame(config["Events"])
options_info = pd.DataFrame(config["Options"])

places = pd.merge(places, places_info, left_on="place", right_index=True)
people = pd.merge(people, people_info, left_on="person", right_index=True)
# %%

plt.figure(figsize=(8, 6))
sns.scatterplot(data=places, x="time", y="num_people", hue="activity", ci=False, linewidth=0)

# %% Hist num_people
g = sns.FacetGrid(places, col="name", hue="activity", col_wrap=4, despine=False)
g.map_dataframe(sns.histplot, x="num_people", binwidth=1)
g.set_axis_labels("Num People", "Count")
g.add_legend()

# %% Hist occupancy
places["occupancy"] = places["num_people"] / places["capacity"]
g = sns.FacetGrid(places, col="name", hue="activity", col_wrap=4, despine=False)
g.map_dataframe(sns.histplot, x="occupancy")
g.set_axis_labels("Occupancy", "Count")
g.set(xlim=(0, 1), ylim=(0, None))
g.add_legend()

# %% Hist air_quality
g = sns.FacetGrid(places, col="name", hue="activity", col_wrap=4, despine=False)
g.map_dataframe(sns.histplot, x="air_quality")
g.set_axis_labels("Air Quality", "Count")
g.add_legend()

# %% Timeline num_people
g = sns.FacetGrid(places, col="name", hue="activity", col_wrap=4, despine=False)
g.map_dataframe(sns.scatterplot, x="time", y="num_people", ci=False, linewidth=0)
g.set_axis_labels("Time", "Num People")
g.set(xlim=(0, 1440), ylim=(0, None))
g.add_legend()

# %% Timeline air_quality
g = sns.FacetGrid(places, col="name", hue="activity", col_wrap=4, despine=False)
g.map_dataframe(sns.lineplot, x="time", y="air_quality", ci=False)
g.set_axis_labels("Time", "Air Quality")
g.set(xlim=(0, 1440), ylim=(0, None))
g.add_legend()


# %% Timeline place per person
sns.catplot(x="time", y="name", hue="activity", kind="swarm", data=people)

# %% Count of activities per person
sns.catplot(x="name", hue="activity", kind="count", data=people, aspect=2)

# %% Risk per person

plt.figure(figsize=(10, 8))
sns.lineplot(
    data=people, x="time", y="risk", hue="department", size="name", legend="full"
)


# %%

nodes = places_info
# nodes = places_info.iloc[np.unique(people.place)].reset_index()

edges = []
for name, group in people.groupby("person"):
    # print(group)
    a = group.place.values
    b = group.place.shift(1).values

    x = np.vstack([b, a]).T
    x = x[~np.isnan(x).any(axis=1), :]
    edges.append(x)

edges = np.concatenate(edges).astype(np.uint8)
u, counts = np.unique(edges, axis=0, return_counts=True)
edges = np.concatenate((u, counts[:, None]), axis=1)


# %%

import networkx as nx

G = nx.Graph()

k = 0
for n in nodes.to_dict("records"):
    G.add_node(k, attr_dict=n)
    k += 1

for e in edges:
    G.add_edge(e[0], e[1], weight=e[2])

pos = nx.kamada_kawai_layout(G)
pos = nx.circular_layout(G)
cmap = plt.cm.tab10
categories = pd.unique(nodes.activity)
activities = pd.Categorical(nodes.activity, categories)
m = len(categories)

plt.figure(figsize=(8, 8))
nx.draw(
    G,
    pos=pos,
    with_labels=True,
    node_color=activities.codes / m,
    node_shape="o",
    vmin=0.0,
    vmax=1.0,
    cmap=cmap,
    width=edges[:, 2]*0.25,
    labels=nodes.name,
    edge_color="#d9d9d990",
    node_size=10 * nodes.area * nodes.height,
)

for i in range(6):
    plt.scatter([], [], c=[cmap(i / m)], label=activities.categories[i])

plt.legend()


# %%

import igraph

g = igraph.Graph()
g.add_vertices(len(nodes))
for key in nodes:
    g.vs[key] = nodes[key]
# g.vs['label'] = G.vs['name']
# g.add_edges(edges.tolist())
# g.add_edges(list(map(tuple, edges)))
g.add_edges(edges[:, :2])
g.es["weight"] = edges[:, 2]

layout = g.layout("kk")
igraph.plot(g, layout=layout, bbox=(500, 500), vertex_label=g.vs["name"])
# %%
