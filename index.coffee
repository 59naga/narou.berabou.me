angular.element(document).ready ->
  angular.bootstrap document,[appName]

appName= 'narou'
appDomain= 'http://ncode.syosetu.com/'
appDependencies= [
  'ui.router'
  'ngStorage'

  'ngAnimate'
  'angular-loading-bar'
  'toastr'
]
app= angular.module appName,appDependencies

app.directive 'img',($state,$rootScope)->
  (scope,element)->
    return unless $state.current.name is 'root.view'
    unless $rootScope.$storage.narou.artwork
      element.parent().replaceWith '<del>＜非表示にされた挿絵＞</del>'

app.run ($rootScope,$localStorage,$window,$timeout,$state)->
  $rootScope.$storage= $localStorage.$default({narou:{page:'',artwork:true}})
  $rootScope.read= (page)->
    page= page.replace /^https?:\/\//,''
    page= page.replace /^ncode.syosetu.com\//,''
    page= page.replace /^novel18.syosetu.com\//,''
    [id,page]= page.split '/' 
    page= 1 unless page

    $state.go 'root.view',{id,page},{reload:yes}

  em= 24
  lineHeight= 1.5
  $rootScope.$on '$viewContentLoaded',->
    if $state.params.id
      $rootScope.$storage.narou.page= $state.params.id
      $rootScope.$storage.narou.page+= '/'+$state.params.page
    
    $timeout ->
      # http://stackoverflow.com/questions/15195209/how-to-get-font-size-in-html
      contents= document.querySelector '#novel_honbun'
      if contents
        em= parseInt $window.getComputedStyle(document.querySelector('#novel_honbun'),null).getPropertyValue 'font-size'
        
      $window.scroll 99999,0

  $window.addEventListener 'keydown',(event)->
    next= ->
      $state.params.page++
      $state.go $state.current.name,$state.params,{reload:yes}
    prev= ->
      return if $state.params.page < 2
      $state.params.page--
      $state.go $state.current.name,$state.params,{reload:yes}
    enter= ->
      i= 0
      nextLineWidth= em*lineHeight
      tick= ->
        i+= 2
        $window.scroll $window.scrollX - 2,0
        $timeout tick if i < nextLineWidth

      $timeout tick

    switch event.keyCode
      # j
      when 74 then next()
      # z
      when 90 then next()
      # k
      when 75 then prev()
      # x
      when 88 then prev()

      else enter()

app.config ($urlRouterProvider)->
  $urlRouterProvider.when '','/'

app.config ($stateProvider)->
  $stateProvider.state 'root',
    url: '/'
    templateUrl: 'root.html'

  $stateProvider.state 'root.view',
    url: ':id?page'
    templateProvider: ($q,$stateParams,$http,$rootScope,$window,toastr)->
      {id,page}= $stateParams
      page?= 1

      api= $window.location.origin+'/scrape/'
      url= appDomain+id+'/'+page
      uri= api+url

      console.log 

      $http.get uri
      .then (result)->
        html= result.data?.match(/\<body.+?\>([\s\S]+?)<\/body>/)[1]

        div= document.createElement 'div'
        div.innerHTML= html
        contents= div.querySelector '#container'

        # Remove <style>
        style.parentNode.removeChild style for style in (contents.querySelectorAll 'style')

        # href="/id/page" => sref="view({id,page})"
        for btns in contents.querySelectorAll '.novel_bn'
          for btn in btns.querySelectorAll 'a'
            [id,page]= btn.getAttribute('href')?.slice(1).split '/'

            # re-sort next/prev navigator
            if page.length
              btn.setAttribute 'ui-sref',"root.view({id:'"+id+"',page:'"+page+"'})"
              if ~~page > ~~$stateParams.page
                btn.textContent= '＜次のページ(j)'
              else
                btn.textContent= '前のページ(k)＞'
                btn.parentNode.insertBefore btn.nextSibling,btn

            else
              btn.parentNode.removeChild btn

          # Add top button
          topButton= document.createElement 'a'
          topButton.textContent= '∧'
          topButton.setAttribute 'ui-sref','^'
          btns.appendChild topButton

        # relative to absolute url
        toc= div.querySelector '.contents1 a'
        toc?.setAttribute 'href',appDomain.slice(0,-1)+(toc.getAttribute 'href')

        # <title>
        title= toc.textContent
        subtitle= (div.querySelector '.novel_subtitle').textContent
        chapterTitle= (div.querySelector '.chapter_title')?.textContent

        $rootScope.title= ''
        $rootScope.title+= subtitle+ ' ' if subtitle
        $rootScope.title+= chapterTitle if chapterTitle
        $rootScope.title+= ' / ' if $rootScope.title
        $rootScope.title+= title if title
        $rootScope.title+= ' powered by '

        contents.innerHTML

      .catch (error)->
        html= error.data?.match(/\<body.+?\>([\s\S]+?)<\/body>/)[1]
        div= document.createElement 'div'
        div.innerHTML= html
        contents= div.querySelector '#container .description'

        reason= angular.element(contents).text()
        toastr.error url.slice(7),reason

        $q.reject error
