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
    return unless $state.current.name is 'root.novel.page'
    unless $rootScope.$storage.narou.artwork
      element.parent().replaceWith '<del>＜非表示にされた挿絵＞</del>'

app.run ($rootScope,$window,$timeout,$state)->
  saveScroll= null

  timeout= null
  $window.addEventListener 'scroll',->
    return unless $state.current.name is 'root.novel.page'
    return if saveScroll is off
    $timeout.cancel timeout

    timeout= $timeout ->
      $state.params.scrollX= $window.scrollX
      remind $state.params

      $state.go $state.current.name,$state.params
    ,50

  em= 24
  lineHeight= 1.5
  remind= ({id,page,scrollX})->
    $rootScope.$storage.narou.page= id
    $rootScope.$storage.narou.page+= '/'+page
    $rootScope.$storage.narou.page+= '/'+scrollX if scrollX
    
  $rootScope.$on '$viewContentLoaded',->
    saveScroll= null

    $timeout ->
      # http://stackoverflow.com/questions/15195209/how-to-get-font-size-in-html
      contents= document.querySelector '#novel_honbun'
      if contents
        em= parseInt $window.getComputedStyle(document.querySelector('#novel_honbun'),null).getPropertyValue 'font-size'
        
      $window.scroll $state.params.scrollX,0

  $window.addEventListener 'keydown',(event)->
    event.preventDefault()

    next= ->
      saveScroll= off
      $state.params.scrollX= 99999
      $state.params.page++
      $state.go $state.current.name,$state.params,{reload:yes}
    prev= ->
      return if $state.params.page < 2
      saveScroll= off
      $state.params.scrollX= 99999
      $state.params.page--
      $state.go $state.current.name,$state.params,{reload:yes}
    enter= (left=yes)->
      i= 0
      nextLineWidth= em*lineHeight
      tick= ->
        i+= 2

        if left
          $window.scroll $window.scrollX + 2,0
        else
          $window.scroll $window.scrollX - 2,0

        $timeout tick if i < nextLineWidth

      $timeout tick

    return if event.keyCode in [27,16,17,18,91] # esc,tab,control,shift,option,command
    return next() if event.keyCode in [74,90] # j,z
    return prev() if event.keyCode in [75,88] # k,x

    # default left scroll for vertical 1 line
    enter event.shiftKey or event.keyCode is 39# →

app.run ($rootScope,$localStorage,$window,$timeout,$state)->
  $rootScope.$storage= $localStorage.$default({narou:{page:'',artwork:true}})
  $rootScope.read= (page)->
    page= page.replace /^(https?:\/\/)?ncode.syosetu.com\//,''
    page= page.replace /^(https?:\/\/)?novel18.syosetu.com\//,''
    page= page.replace $window.location.origin+'/#/',''
    [id,page,scrollX]= page.split '/'
    page= 1 unless page
    scrollX= 99999 unless scrollX

    $state.go 'root.novel.page',{id,page,scrollX},{reload:yes}

app.config ($urlRouterProvider)->
  $urlRouterProvider.when '','/'

app.config ($stateProvider)->
  $stateProvider.state 'root',
    url: '/'
    templateUrl: 'root.html'

app.config ($stateProvider)->
  $stateProvider.state 'unavailable',
    url: '/unavailable'
    templateUrl: 'unavailable.html'

  $stateProvider.state 'root.novel',
    url: ':id'
    template: '<div ui-view></div>'
    controller: ($state,$window,$location)->
      return $state.go 'unavailable' if $window.navigator.userAgent.match /(MSIE|Firefox)/
      return unless $state.current.name is 'root.novel'

      {id}= $state.params
      page= $location.search().page ? 1
      scrollX= 99999

      $state.go 'root.novel.page',{id,page,scrollX},{reload:yes}

  $stateProvider.state 'root.novel.page',
    url: '/:page?scrollX'
    templateProvider: ($q,$stateParams,$http,$rootScope,$window,toastr)->
      {id,page}= $stateParams
      page= 1 unless page

      api= $window.location.origin+'/scrape/'
      url= appDomain+id+'/'+page
      uri= api+url

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
              btn.setAttribute 'ui-sref',"root.novel.page({id:'"+id+"',page:'"+page+"',scrollX:99999})"
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
          topButton.setAttribute 'ui-sref','root'
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
