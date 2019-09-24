# spec/acceptance/orders_spec.rb
require 'rails_helper'
require 'rspec_api_documentation/dsl'
# resource 'Orders' do
#   explanation "Orders resource"
#
#   header "Content-Type", "application/json"
#
#   get '/orders' do
#     # This is manual way to describe complex parameters
#     parameter :one_level_array, type: :array, items: {type: :string, enum: ['string1', 'string2']}, default: ['string1']
#     parameter :two_level_array, type: :array, items: {type: :array, items: {type: :string}}
#
#     let(:one_level_array) { ['string1', 'string2'] }
#     let(:two_level_array) { [['123', '234'], ['111']] }
#
#     # This is automatic way
#     # It's possible because we extract parameters definitions from the values
#     parameter :one_level_arr, with_example: true
#     parameter :two_level_arr, with_example: true
#
#     let(:one_level_arr) { ['value1', 'value2'] }
#     let(:two_level_arr) { [[5.1, 3.0], [1.0, 4.5]] }
#
#     context '200' do
#       example_request 'Getting a list of orders' do
#         expect(status).to eq(200)
#       end
#     end
#   end
#
#   put '/orders/:id' do
#
#     with_options scope: :data, with_example: true do
#       parameter :name, 'The order name', required: true
#       parameter :amount
#       parameter :description, 'The order description'
#     end
#
#     context "200" do
#       let(:id) { 1 }
#
#       example 'Update an order' do
#         request = {
#           data: {
#             name: 'order',
#             amount: 1,
#             description: 'fast order'
#           }
#         }
#
#         # It's also possible to extract types of parameters when you pass data through `do_request` method.
#         do_request(request)
#
#         expected_response = {
#           data: {
#             name: 'order',
#             amount: 1,
#             description: 'fast order'
#           }
#         }
#         expect(status).to eq(200)
#         expect(response_body).to eq(expected_response)
#       end
#     end
#
#     context "400" do
#       let(:id) { "a" }
#
#       example_request 'Invalid request' do
#         expect(status).to eq(400)
#       end
#     end
#
#     context "404" do
#       let(:id) { 0 }
#
#       example_request 'Order is not found' do
#         expect(status).to eq(404)
#       end
#     end
#   end
# end
