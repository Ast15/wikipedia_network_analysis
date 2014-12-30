# install.packages("igraph")
library(igraph)

###############################################
#   First solution : pages from categories    #
###############################################

edges = read.csv("data/edges.csv", colClasses = c("character", "character"))
vertex = read.csv("data/vertex.csv", colClasses = c("character", "character", "integer", "character", "character"))
# columns order of the csv : "category","expertneeded","length","name","stub"
# name first
vertex_tmp = vertex[,c(4,5)]
vertex_tmp$expertneeded = vertex$expertneeded
vertex_tmp$category = sub("Category:", "", vertex$category)
vertex_tmp$length = vertex$length
vertex = vertex_tmp
vertex$stub = ifelse(vertex$stub=="True", TRUE, FALSE)
vertex$expertneeded = ifelse(vertex$expertneeded=="True", TRUE, FALSE)

graph <- graph.data.frame(edges, directed=TRUE, vertices=vertex)

# dot file for viz
write.graph(graph, "myGraph.dot", format = "dot")
# gml file for viz
write.graph(graph, "myGraph.gml", format = "gml")


# agregated by categories
category.f <- as.factor(V(graph)$category)
category.nums <- as.numeric(category.f)
graph.c <- contract.vertices(graph, category.nums)
E(graph.c)$weight <- 1
graph.c <- simplify(graph.c)

# selection of edges
summary(E(graph.c)$weight)
hist(E(graph.c)$weight, breaks=50)
sum(E(graph.c)$weight<17)
E(graph.c)$weight[E(graph.c)$weight<10] = 0

category.names <- sort(unique(V(graph)$category))
cat.size <- as.vector(table(V(graph)$category))
plot(graph.c, vertex.size=sqrt(cat.size)/2, vertex.label=category.names, vertex.label.color=rainbow(length(V(graph.c)), alpha=1),
         vertex.color=rainbow(length(V(graph.c)), alpha=0.3), edge.width=sqrt(E(graph.c)$weight)/30,
         edge.arrow.size=0.05, layout=layout.circle, vertex.label.cex=0.7)
# vertex.label.dist=1.5,
# vertex.color=V(graph.c)
# layout : layout.drl layout.kamada.kawai layout.circle

# gml file for viz
write.graph(graph.c, "myGraph_agregated.gml", format = "gml")


# strength /!\ n'a de sens qu'avec des weigth
s_in = graph.strength(graph, mode = 'in')
summary(s_in)
hist(s_in, breaks = 50, col="pink", xlab="Vertex In-Strength", ylab="Frequency", main="")
s_out = graph.strength(graph, mode = 'out')
summary(s_out)
hist(s_out, breaks = 50, col="pink", xlab="Vertex Out-Strength", ylab="Frequency", main="")

##########################################
#   Second solution : pages from list    #
##########################################

edges2 = read.csv("data/edges2.csv", colClasses = c("character", "character"))
vertex2 = read.csv("data/vertex2.csv", colClasses = c("character", "character", "character", "integer"))
# name first
vertex2_tmp = vertex2[,c(2:4)]
vertex2_tmp$expertneeded = vertex2$expertneeded
vertex2 = vertex2_tmp
vertex2$stub = ifelse(vertex2$stub=="True", TRUE, FALSE)
vertex2$expertneeded = ifelse(vertex2$expertneeded=="True", TRUE, FALSE)

graph <- graph.data.frame(edges2, directed=TRUE, vertices=vertex2)

# dot file for viz
write.graph(graph, "myGraph2.dot", format = "dot")
# gml file for viz
write.graph(graph, "myGraph2.gml", format = "gml")


plot(graph)
igraph.options(vertex.size=3, vertex.label=NA,
               edge.arrow.size=0.5)
par(mfrow=c(1, 2))
plot(graph, layout=layout.circle)
title("5x5x5 Lattice")
plot(graph, layout=layout.fruchterman.reingold)
title("Blog Network")



# absence of loops and multi-edges
is.simple(graph)

vcount(graph)
ecount(graph)
neighbors(graph,5)

# degrees
# question : heterogeneous ?
d_in = degree(graph, mode="in")
summary(d_in)
hist(d_in, breaks = 50, col="lightblue", xlab="Vertex In-Degree", ylab="Frequency", main="")
# très élevé
sort(d_in[d_in > 170], decreasing=T)
# 1er pic
sort(d_in[d_in > 110 & d_in <= 170 ], decreasing=T)
# 2iem pic : les distributions
sort(d_in[d_in > 70 & d_in <= 110 ], decreasing=T)
# question : est-ce que ça correspond à ce qui est fondamental en stat ?
# qu'est-ce qui caractérise ce qui fait le plus référence en stat sur wikipedia ?


d_out = degree(graph, mode="out")
summary(d_out)
hist(d_out, breaks = 50, col="lightblue", xlab="Vertex In-Degree", ylab="Frequency", main="")

# on a des points d'entrée dans la stat comme "Epidemiology", "Econometrics"
sort(d_out[d_out > 130], decreasing=T)
# 1er pic
sort(d_out[d_out > 110 & d_out <= 170 ], decreasing=T)
# 2iem pic : les distributions
sort(d_out[d_out > 70 & d_out <= 110 ], decreasing=T)

# log degree

dd_in <- degree.distribution(graph, mode="in")
d <- 1:max(d_in)-1
ind <- (dd_in != 0)
d[1]=0.3 # we add an epsilon to the 0 in-degree
plot(d[ind], dd_in[ind], log="xy", col="blue",
     xlab=c("Log-In-Degree"), ylab=c("Log-Intensity"),
     main="Log-Log In-Degree Distribution")

dd_out <- degree.distribution(graph, mode="out")
d <- 1:max(d_out)-1
outd <- (dd_out != 0)
d[1]=0.3 # we add an epsilon to the 0 out-degree
plot(d[outd], dd_out[outd], log="xy", col="blue",
     xlab=c("Log-Out-Degree"), ylab=c("Log-Intensity"),
     main="Log-Log Out-Degree Distribution")

# hexbin viz
library(hexbin)
# in
x <- log(d[ind])
y <- log(dd_in[ind])
bin<-hexbin(x, y, xbins=50)
plot(bin, main="Hexagonal Binning") 
# out
x <- log(d[outd])
y <- log(dd_out[outd])
bin<-hexbin(x, y, xbins=50)
plot(bin, main="Hexagonal Binning") 

# in + out degree
d_total <- degree(graph, mode="total")


## understand the manner in which vertices of different degrees are linked with each other.
# average degree of the neighbors of a given vertex
# in + out degree
a.nn.deg <- graph.knn(graph,V(graph))$knn
plot(d_total, a.nn.deg, col="goldenrod", xlab=c("Vertex Degree"),
     ylab=c("Average Neighbor Degree"))
plot(d_total, a.nn.deg, log="xy", col="goldenrod", xlab=c("Log Vertex Degree"),
     ylab=c("Log Average Neighbor Degree"))
# Average neighbor degree versus vertex degree (log–log scale)


x <- log(d_total)
y <- log(a.nn.deg)
bin<-hexbin(x, y, xbins=50)
plot(bin, main="Hexagonal Binning", xlab=c("Log Vertex Degree"), ylab=c("Log Average Neighbor Degree") ) 






# the graph is not connected

is.connected(graph, mode="weak")
# A digraph G is weakly connected if its underlying graph (i.e., the result of stripping away the labels ‘tail’ and ‘head’ from G ) is connected.

is.connected(graph, mode="strong") 
#It is called strongly connected if every vertex v is reachable from every u by a directed walk.

# nb of clusters
no.clusters(graph)
# there is only 4 vertice not in the main cluster
clusters(graph, mode="strong")
clusters(graph, mode="weak") # par défaut : weak
V(graph)[clusters(graph, mode="weak")$membership==2]

# acyclic ? (no cycles ?)
is.dag(graph)
# nb of cycles ?

# adjacency matrix
get.adjacency(graph)


diameter(graph, weights=NA) # non-pertinent car lié à la façon dont on a extrait les articles parlant de stats


# graph partitioning
kc <- fastgreedy.community(graph)
length(kc)
sizes(kc)
membership(kc)
plot(kc,karate)

library(ape)
dendPlot(kc,mode="phylo")



#g.full <- graph.full(7)
#g.ring <- graph.ring(7)
#g.tree <- graph.tree(7, children=2, mode="undirected")
#g.star <- graph.star(7, mode="undirected")
# par(mfrow=c(2, 2))
# plot(g.full)
# plot(g.ring)
# plot(g.tree)
# plot(g.star)
