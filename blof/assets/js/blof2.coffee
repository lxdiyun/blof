angular.module 'blof', ['ngResource']
	.config ['$httpProvider', ($httpProvider) ->
		$httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
		$httpProvider.defaults.xsrfCookieName = 'csrftoken'
		return
	]

	.service 'authState', ->
		user: null

	.factory 'api', ($resource) ->
		add_auth_header = (data, headersGetter) ->
			headers = headersGetter()
			headers['Authorization'] = ('Basic ' + btoa(data.username + ':' + data.password))
			return

		return {
			auth: $resource('/api/auth/#', {}, {
				login: { method: 'POST', transformRequest: add_auth_header },
				logout: { method: 'DELETE' }
			}),
			users: $resource('/api/users/#', {}, {
				create: { method: 'POST' }
			}),
			posts: $resource('/api/posts/#', {}, {
				list: { method: 'GET', isArray: true },
				create: { method: 'POST' },
				detail: { method: 'GET', url: '/api/posts/:id' },
				delete: { method: 'DELETE', url: '/api/posts/:id' }
			})
		}

	.controller 'authController', ($scope, api, authState) ->
		$('#id_auth_form input').checkAndTriggerAutoFillEvent()

		$scope.authState = authState

		$scope.getCredentials = ->
			username: $scope.username, password: $scope.password

		$scope.login = ->
			api.auth.login $scope.getCredentials()
			.$promise.then (data) ->
				authState.user = data.username
				return
			.catch (data) ->
				alert(data.data.detail)
				return
			return

		$scope.logout = ->
			api.auth.logout ->
				authState.user = null
				return
			return

		$scope.register = ($event) ->
			$event.preventDefault()
			api.users.create $scope.getCredentials()
				.$promise.then $scope.login
				.catch (data) ->
					alert(data.data.username)
					return

	.controller 'postController', ($scope, api, authState) ->
		$scope.authState = authState

		$scope.list = ->
			api.posts.list (data) ->
				$scope.posts = data
				return
			return
		$scope.list()

		$scope.create = ->
			data = body: $scope.body
			api.posts.create data, (data) ->
				$scope.body = ''
				$scope.posts.unshift(data)
				return
			return

		$scope.delete = (id) ->
			api.posts.delete {id: id}, ->
				$scope.posts.splice $scope.utils.getPostIndex(id), 1
				return
			return

		$scope.utils = getPostIndex: (id) ->
			return _.indexOf( $scope.posts, _.findWhere($scope.posts, {id: id}))
