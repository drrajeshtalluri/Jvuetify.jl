import Weave
using DataFrames
using JSON
using RCall
import PlotlyJS

function jhtml(source::String)
    Weave.weave(source,"pandoc")
    ofile = split(basename(source),".")[1] * ".md"
    htmlfile = split(basename(source),".")[1] * ".html"
    pdir = dirname(@__FILE__)
    vtemplate = joinpath(pdir, "../templates/vuetify.html")
    vcss = joinpath(pdir, "../templates/vuetify.css")
    run(`pandoc -f markdown -t html $ofile -o $htmlfile --katex --section-divs --template $vtemplate --toc --css $vcss`)
end


function htmltable(df;title="")
  function df2json(df::DataFrame)
    len = length(df[:,1])
    indices = names(df)
    jsonarray = [Dict([string(index)=> (df[index][i]) for index in indices]) for i in 1:len]
    return JSON.json(jsonarray)
  end
  trows = df2json(df)
  thead = JSON.json([Dict("value"=>i,"text"=>i) for i in names(df)] )
  return """
  ```{=html}
  <vue-data-table>
  <template slot="title"><span style="color:#4e6b95; font-weight:normal">$title</span></template>
  <template slot-scope="{search, cfilter}">
  <v-data-table dense
      :headers=$thead
      :items=$trows
      :search = "search"
      :custom-filter = "cfilter"
      multi-sort
      class="elevation-1"
    >
    </v-data-table>
  </template>
  </vue-data-table>
  ```"""
end
function jggplot(p::String,type::String; width = 8, height =5)
    jggplot(; width = width, height = height)
    R"""
    ggsave(filename = $p, width = $width, height = $height,type = "cairo", dpi = 300)
    """
    if type == "markdown"
      return "![]($p)"
    else
      return "<img src=$p>"
    end
end

function jggplot(;width = 8, height =5)
  R"library(hrbrthemes)"
  R"library(ggplot2)"
  p = R"""ggplot(mtcars, aes(mpg, wt)) +
    geom_point(aes(color=factor(carb))) +
    labs(x="Fuel efficiency (mpg)", y="Weight (tons)",
         title="Seminal ggplot2 scatterplot example",
         subtitle="A plot that is only useful for demonstration purposes",
         caption="Brought to you by the letter 'g'") +
    scale_color_ipsum() +
    theme_ipsum_rc()"""
end


function plotlygraph(a,pid)
  pdata = json(a.plot)
  println("""```{=html}
    <plotly-vue pid=$pid pdata = '$pdata'></plotly-vue>
  ```""")
end
