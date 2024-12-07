#set page(paper: "a4", margin: (top: 5.2cm, bottom: 5.7cm, outside: 4.6cm, inside: 4.7cm), )

#set text(font: "Times", size: 11pt)
// #set text(font: "PT Serif", size: 11pt)


#set par(justify: true)

#show link: it => {
  text(fill: blue)[#underline[#it]]
}

#show figure.caption: it => {
  v(0.2cm)
  set text(size: 10pt)
  if it.supplement == [Figure] {
    [*Fig. #context(it.counter.display())* ]
  } else {
    [*#it.supplement #context(it.counter.display())* ]
  }
  it.body

  v(0.6cm)
}

#set page(
  footer: text(fill: gray)[
    #grid(columns: (1fr, auto), gutter: 2em)[_ARCH 6508 / CS 6492 / ID6508 Shape Grammars. A Economou	pp. xx-yy. © Georgia Institute of Technology, Fall 2024_][#context{ 
      counter(page).display(
      "1",
  )
  }]
],
header: text(fill: gray)[#context{ 
  if counter(page).get().at(0) >= 2 {
  align(right)[Zhen Li]
  }
  }],
numbering: "1"
)
= Lindenmayer Systems in Shape Machine

#v(84pt)

*Zhen Li*\
Georgia Institute of Technology, United States\
#text(fill: blue)[#underline[zhenli.craig\@gatech.edu]]

#show raw: it => text(font: "SF Mono", box(outset: (top:0.3em, bottom: 0.3em), inset: (left: 0.3em, right: 0.3em), fill: rgb(240, 241,243), radius: 0.2em, text(weight: 600)[#it]))

#let block_name = it => {
  box(outset: (top:0.18em, bottom: 0.3em), inset: (left: 0.3em, right: 0.3em), fill: rgb(0,255,0), stroke: 0.8pt+black, radius: 1em, text(font:"SF Pro Text", size: 10pt)[#it])
}

#v(36pt)

This project experiments with a certain type of Lindenmayer Systems (L-Systems) within Shape Machine to expand shape grammars' visual computational capabilities.  L-Systems are well-suited for generating recursive, fractal-like structures. By bringing L-Systems into Shape Machine, this project aims to enable recursive shape-based rule applica-tions within a CAD environment, creating opportunities for intricate patterning in architectural, industrial, and visual design. Specifically, this project explores programmatically generating DrawScripts from L-Systems rules and visualizes the resulting designs. The integration of L-Systems in Shape Machine offers a novel approach to shape grammar design, combining the generative power of L-Systems with the formalism of shape grammars to create complex, visually engaging designs.

// #pagebreak()
#v(36pt)

#set par(
  first-line-indent: 2em, 
  justify: true,
  spacing: 1.5em
  )


#show heading.where(level: 2): it => {
  v(2em)
  set text(size: 12pt, weight: 700)
  it
  v(1em)
}


#show heading.where(level: 3): it => {
  v(0.5em)
  set text(size: 11pt, weight: 700)
  it
  v(0.5em)
}

#set heading(
  numbering:  (..nums) => {
    let tail = nums.pos()
    tail.slice(1)
      .map(str)
      .join(".")
  }
)


== Introduction

Lindenmayer Systems (or L-Systems) are a mathematical formalism introduced by biologist Aristid Lindenmayer in 1968. @LINDENMAYER1968280@Prusinkiewicz1990TheAB They were initially developed to model the growth of plant structures but have since found applications in computer graphics, particularly in generating fractals and procedural natural forms.


#figure(
  image("media/image1.png"),
  caption: "Fractal geometry produced by Lindenmayer systems"
)

L-Systems operate as a set of rewriting rules (also known as gram-mar), where symbols in a string are replaced iteratively according to predefined rules.@Prusinkiewicz1990TheAB These systems consist of three main components:

•	*_Alphabet_*: A set of symbols used to construct strings.

•	*_Axiom_*: An initial string or starting point.

•	*_Production Rules_*: A set of rules dictating how symbols are replaced or transformed in each iteration.

The integration of L-Systems with turtle graphics is a powerful tool in computer graphics, enabling the visualization of complex geometries and patterns. @bourke_lsystems Turtle graphics interprets the symbols of an L-System as commands to draw or manipulate the cursor on a Cartesian plane. @turtle Commonly used commands include:

#figure(
  table(columns: (auto, 1fr), align: left)[`F`][Move forward while drawing a line.][`+`][Turn right by a specified angle.][`-`][Turn left by a specified angle.][`[`][Save the current position and orientation (used for branching structures).][`]`][Restore the last saved position and orientation.][`|`][Turn around (180 degrees).],

  caption: "An action table for L-systems"
)


For example, consider the Koch curve: a string of characters (symbols) is rewritten on each iteration according to some replacement rules. The initial string (axiom)
$
F+F+F+F
$
And a rewriting rule:
$
F --> F+F-F-F F+F+F-F
$
After one iteration the following string would result
$
  &F+F-F-F F+F+F-F + F+F-F-F F+F+F-F \
+ &F+F-F-F F+F+F-F + F+F-F-F F+F+F-F
$
They could be visualized as below:
 	 
#figure(
  image("kochExample.png", width: 86%),
  caption: "Koch curve example"
)

In this project, we will programmatically generate the shape grammars for L-systems, facilitating a richer integration between sophisticated fractal geometry and the ergonomic design environment provided by Shape Machine. @Stiny1971ShapeGA Specifically, we will be focusing on a certain type of geometry that can be generated through a unified logic where all the alphabet characters represent moving forward. @lsys2


== Motivation

The integration of L-Systems into architectural and design workflows offers a transformative approach to generating and visualizing complex geometries. @LINDENMAYER1968280@Prusinkiewicz1990TheAB As a procedural fractal geometry generation method, L-Systems provide architects and designers with tools to explore fractal patterns, branching structures, and intricate geometrical forms that are often difficult to conceptualize through traditional means. 

However, the sophisticated fractal geometries usually require a precise vector computation and can be difficult for human designer to implement. By leveraging the inherent logic of iterative rewriting and visualizing the results through Shape Machine and automated rule generation, designers can rapidly prototype intricate geometries and experiment with various configurations. This not only enhances creativity but also allows for the exploration of patterns and forms that align with natural principles, leading to more harmonious and functional designs.


== Methodology

In this section, we will discuss the implementation of L-Systems in Shape Machine.

=== Implementing a state machine for turtle graphics in Shape Machine
In computer graphics, turtle graphics are vector graphics using a relative cursor (the "turtle") upon a Cartesian plane ($x$ and $y$ axis). The turtle moves with commands that are relative to its own position, such as “move forward 10 units” and “turn left 90 degrees”. The pen carried by the turtle can also be controlled, by enabling it, setting its color, or setting its width. 

Unlike traditional turtle graphics environment, where a simple line implicitly carries the semantic of direction, a single line alone in Shape Machine does not carry such information. To implement a turtle machine in Shape Machine, the first thing we need to add is a point to represent the direction. For every line we draw a point with the same attributes (color).



#figure(
  image("media/image4.png"),
  caption: "Turtle graphics in Shape Machine"
)






Another addition is a point that indicates termination. This is to avoid the unwanted matches as shown by the red point and line in @unwanted_match. The termination point uses the different colors so that Shape Machine doesn’t confuse termination points with direction points.

#figure(
  image("media/image5.png", width: 50%),
  caption: "Unwanted match"
)<unwanted_match>



=== Simulating parallel application in Shape Machine
Some L-System design might contain multiple rules, and they are usually parallelly rewritten. @LINDENMAYER1968280@lsys2 Consider the following rule for dragon curve:


#figure(
  image("media/image6.png"),
  caption: "Dragon curve rules"
)<dragon_c>



For the axiom $F+G$, the L-system should produce $F+G + F-G$ after first application.

However, if it is rewritten sequentially, the resulting string will be $F+G+G$ after the first application of the left-hand side rule ($F->F+G$), and then $F+F-G+F-G$ after the second application of the right-hand side rule ($G->F-G$). This is no longer a dragon curve, and the resulting string's semantic would diverge in traditional turtle graphics environment and Shape Machine — In turtle graphics, $F$s should be of same length. However, if we apply the DrawScripts sequentially, the first $F$ will be $√2$ times longer.

To simulate parallel rewriting behavior in Shape Machine, we can borrow some compiler techniques @dragon to make Shape Machine “blind” to the intermediate application result –
we can rewrite rules to simulate parallel rewriting in a sequential manner, as shown in @mod_rules.

#figure(
$
cases(
  F -> F+G,
G -> F-G,
)
quad ==> quad
cases(
  #grid(columns: (auto, auto), row-gutter: 0.5em, column-gutter: 1em,
[$F  ->  F'+G'$],
grid.cell(rowspan: 2,align: horizon)[
#block_name[gen_rule]
],
[
$G  ->  F'-G'$
]),

#v(0.2em),

#grid(columns: (auto, auto), row-gutter: 0.5em, column-gutter: 1em,
[$F' ->  F$],
grid.cell(rowspan: 2,align: horizon)[
#h(2.35em) #block_name[normal_to_thick]
],
[
$G' ->  G$
]),

// F' ->  F,
// G' ->  G,
)

$,
caption: [Modified rules]
)<mod_rules>





To translate this change into Shape Machine, we can simply change the attribute of the terminating black points. In the current implementation, the terminating black point is activated (`"Black Thick"`) in the symbols without prime signs ($F$ and $G$), deactivated (`"Black"`) in the symbols with prime signs ($F'$ and $G'$). 

Another DrawScripts block (#block_name[normal_to_thick] in @DrawScripts) for reactivate the terminating points to `"Black Thick"` is then added to the DrawScripts routine. This block will be executed in each iteration after all the generated rules have been executed.

After this change, we can simulate parallel application of multiple rules in Shape Machine.  

 
#figure(
  image("media/image7.png"),
  caption: "Parallel application in Shape Machine"
)<parallel_application>
// Fig. 8 Parallel application in Shape Machine

=== Automated generation of DrawScripts from given grammar

Now we can generate DrawScripts for simple L-systems. @DrawScripts is an overview of the DrawScripts program. To generate the rules, the designer can simply provide the rules and apply the leftmost block #block_name[lsys-rule-generator] to a selection of dark green points inside the #block_name[gen_rule] block, which is provided by Shape Machine templates. 


#figure(
  image("media/image8.png"),
  caption: "The DrawScripts program"
)<DrawScripts>


== Results 

Below are some of the experiments made with the rule generator.

#{
  let img_names = (
    "Koch snowflake",
    "Koch anti-snowflake",
    "Tiles",
    "Crystal",
    "Rings",
    "Pentaplexity",

    "Sierpiński arrowhead",
    "Dragon curve",
    "Gosper curve"
  )
  for i in range(1, 10) {
    let img_path = "LSys-export/LSys-export.00"+str(i)+".png"
    figure(
      align(center, box(width: 6in, height: 2.8in, clip: true)[
        #box(width: 6in, height: 3in)[
          #move(dy: -1cm, image(img_path, width: 6in, height: auto))
        ]
      ]),
      caption: img_names.at(i - 1)
    )
  }
}



A fast and convenient way to generate fractal geometry in Shape Machine also enabled some fun variations. There are 3 basic ways to create variation:

1.	Add additional replacement rules after generating fractal shapes. @Gosper_curve_variations shows a Gosper curve variation generated by replacing all lines into arcs.

#figure(
  image("media/image18.png", width: 90%),
  caption: "Gosper curve variations"
)<Gosper_curve_variations>


#figure(
  image("media/image19.png"),
  caption: "The modified program for generating Gosper curve variations"
)<Gosper_curve_variations2>


2.	Modify left-hand side in generated rules. For example, the rule $F --> F F+F-F+F+F F$ will generate an entirely different tessellation when the left-hand side $F$ is mirrored.


 

 #figure(
  {
    image("media/image20.png", width: 90%)

    grid(columns: (1fr, 1fr), gutter: 1em)[
      #image("media/image21.png")][
      #image("media/image22.png")
    ]
  },
  caption: "Tile variations"

 )<Tile_variations>





3.	Modify right-hand side in generated rules. The rule of Pentaplexity, $F++F++F|F-F++F$, will result in different fractal stars shown in @Pentaplexity_variations, if added with some arcs in right-hand side. This is different from simply adding additional replacement rules after generating fractal shapes, because the modification here will remain in the geometry between iterations.


#figure(
  image("media/image23.png"),
  caption: "Pentaplexity variations"
)<Pentaplexity_variations>

== Future Work

We have demonstrated the integration of L-Systems into Shape Machine, enabling the generation of complex fractal geometries through programmatically generated DrawScripts. Future work could focus on transforming the Python logic into a more user-friendly interface within Shape Machine, allowing designers to interact with L-Systems directly. Additionally, expanding the generation rules and exploring more sophisticated fractal patterns could enhance the creative potential of this integration. Further research could also investigate the application of L-Systems in architectural design, industrial design, and graphic design contexts, exploring how these generative systems can inform and enrich the design process.

== Conclusion

The integration of Lindenmayer Systems (L-Systems) into Shape Machine demonstrates a novel and powerful approach to computational design, bridging the generative capabilities of recursive grammars with the precision and versatility of CAD environments. This project has successfully shown how programmatically generated DrawScripts based on L-System rules can produce intricate fractal geometries and enable rich visual exploration in architectural, industrial, and graphic design applications.@LEYTON1988213

By implementing features such as parallel rewriting simulation, termination point adjustments, and automated rule generation, the project has addressed key challenges in adapting L-Systems to the Shape Machine framework. The results showcase the potential of this integration to not only enhance the efficiency of complex pattern generation but also introduce opportunities for creative experimentation through modifications in grammar rules.

The ability to create and customize fractal patterns, as demonstrated through examples like the Koch snowflake, Dragon curve, and Gosper curve variations, opens up avenues for innovative applications in design disciplines. This work highlights the value of combining mathematical formalisms like L-Systems with user-friendly computational tools, enabling designers to prototype and iterate complex forms with ease. Future developments could focus on expanding the library of generative rules, enhancing visualization capabilities, and exploring real world implementations in various design contexts.

Overall, this project lays the groundwork for more sophisticated interactions between shape grammars and generative systems, fostering new possibilities in computational design and visual aesthetics.


#set heading(numbering: none)
#pagebreak()

== References

#bibliography("ref.bib", title: none)