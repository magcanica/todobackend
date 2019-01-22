from django.test import TestCase
from django.core.urlresolvers import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from todo.models import TodoItem

# Create your tests here.
def createItem(client):
	url = reverse('todoitem-list')
	data = {'title': 'Walk the dog'}
	return client.post(url, data, format='json')


class TestCreateTodoItem(APITestCase):
	def setUp(self):
		self.response = createItem(self.client)

	def test_receive_201_created(self):
		self.assertEqual(self.response.status_code, status.HTTP_201_CREATED)	

class TestUpdateTodoItem(APITestCase):
	def setUp(self):
		response = createItem(self.client)
		self.assertEqual(TodoItem.objects.get().completed, False)
		url = response['Location']
		data = {'title': 'walk the dog', 'completed': True}
		self.response = self.client.put(url, data, format='json')

	def test_receive_200_created(self):
		self.assertEqual(self.response.status_code, status.HTTP_200_OK)	