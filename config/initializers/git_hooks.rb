GitHooks.active_repos = [
  'SchoolApi',
  'SycamoreSchool',
  'SycamoreCampus',
  'SycamoreSchoolVue',
  'SchoolAdmin',
  'SchoolVue'
]
GitHooks.approved = {
  add: ['Dev Approved', 'QA Review'],
  remove: ['Dev Review']
}
GitHooks.rejected = {
  remove: ['Dev Review', 'Dev Approved', 'QA Review']
}
GitHooks.review = {
  add: ['Dev Review'],
  remove: ['Dev Approved', 'QA Review']
}
