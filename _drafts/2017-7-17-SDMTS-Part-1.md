---
layout: post
title: SDMTS Part 1 Static Data Exploration
excerpt_separator: <!--more-->
---
In this series I will be exploring the data provided 
by the San Diego Metropolitan Transit System. This 
section will be a quick look at the static data, the
data that provides the schedule and route information. 
 <!--more-->
{% highlight ruby %}
def show
  @widget = Widget(params[:id])
  respond_to do |format|
    format.html # show.html.erb
    format.json { render json: @widget }
  end
end
{% endhighlight %}
