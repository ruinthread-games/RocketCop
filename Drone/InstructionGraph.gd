extends GraphEdit

var graph_output = ''
var output_arrays = []
var eval_ids = null
var dead = -1

var time_node_instance

func log_graph_output(output):
	graph_output += output +"\n"

func get_numerical_value(current_numerical_node,backward_connections):
	if current_numerical_node[0].value == 'log':
		var parent_val = get_numerical_value(backward_connections[current_numerical_node[0]][0],backward_connections)
		var log_str = current_numerical_node[0].log(parent_val)
		log_graph_output(log_str)
		return parent_val
	if current_numerical_node[0].value == 'map_pin':
		return current_numerical_node[0].internal_data[current_numerical_node[2]]
	if current_numerical_node[0].value == 'current_coord':
		# TODO INTERNAL STATE
		pass
	if current_numerical_node[0].value == 'Time':
		return time_node_instance.time_value
	if current_numerical_node[0].value == 'Number':
		return current_numerical_node[0].number
	if current_numerical_node[0].value == 'SingleMath':
		if len(backward_connections[current_numerical_node[0]]) != 1:
			log_graph_output('FUNCTION PIN MISSING')
			return 0
		var parent_node = backward_connections[current_numerical_node[0]][0]
		var parent_val = current_numerical_node[0].apply_function(get_numerical_value(parent_node,backward_connections))
		return parent_val
	if current_numerical_node[0].value == 'DoubleMath':
		if not current_numerical_node[0] in backward_connections:
			log_graph_output('2 MATH OP PINS MISSING')
			return 0
		if len(backward_connections[current_numerical_node[0]]) != 2:
			log_graph_output('1 MATH OP PIN MISSING')
			return 0
		var first_parent = backward_connections[current_numerical_node[0]][0]
		var second_parent = backward_connections[current_numerical_node[0]][1]
		return current_numerical_node[0].apply_operation(get_numerical_value(first_parent,backward_connections), get_numerical_value(second_parent,backward_connections))
	if current_numerical_node[0].value == 'Distance':
		if not current_numerical_node[0] in backward_connections:
			log_graph_output('DISTANCE PINS MISSING')
			return 0
		if len(backward_connections[current_numerical_node[0]]) != 4:
			log_graph_output('%d DISTANCE PINS NOT SET' %(4 - len(backward_connections[current_numerical_node[0]])))
			return 0
		#print(backward_connections[current_numerical_node[0]])
		var first_parent  = backward_connections[current_numerical_node[0]][0]
		var second_parent = backward_connections[current_numerical_node[0]][1]
		var third_parent  = backward_connections[current_numerical_node[0]][2]
		var fourth_parent = backward_connections[current_numerical_node[0]][3]
		var dist = current_numerical_node[0].get_distance( 
			get_numerical_value(first_parent,backward_connections), \
			get_numerical_value(second_parent,backward_connections), \
			get_numerical_value(third_parent,backward_connections), \
			get_numerical_value(fourth_parent,backward_connections))
		return dist
	if current_numerical_node[0].value == 'Interpolate':
		if not current_numerical_node[0] in backward_connections:
			log_graph_output('INTERPOLATE PINS MISSING')
			return 0
		if len(backward_connections[current_numerical_node[0]]) != 3:
			log_graph_output('%d INTERPOLATE PINS NOT SET' %(3 - len(backward_connections[current_numerical_node[0]])))
			return 0
		var first_parent  = backward_connections[current_numerical_node[0]][0]
		var second_parent = backward_connections[current_numerical_node[0]][1]
		var third_parent  = backward_connections[current_numerical_node[0]][2]
		var parents = [backward_connections[current_numerical_node[0]][0],backward_connections[current_numerical_node[0]][0],backward_connections[current_numerical_node[0]][0]]
		
		return current_numerical_node[0].interpolate( 
			get_numerical_value(first_parent,backward_connections), \
			get_numerical_value(second_parent,backward_connections), \
			get_numerical_value(third_parent,backward_connections))
	if current_numerical_node[0].value == 'action':
		for backward in backward_connections[current_numerical_node[0]]:
			pass
		
	if current_numerical_node[0].value == 'Conditional':
		var first = get_numerical_value(backward_connections[current_numerical_node[0]][0],backward_connections)
		var second = get_numerical_value(backward_connections[current_numerical_node[0]][1],backward_connections)
		return current_numerical_node[0].apply_conditional(first,second)
	return 0

func get_bool_value(current_logical_node,backward_connections):
	if current_logical_node[0].value == "Conditional":
		if not current_logical_node[0] in backward_connections:
			log_graph_output('CONDITIONAL PIN MISSING')
			return false
		if len(backward_connections[current_logical_node[0]]) != 2:
			log_graph_output('CONDITIONAL PIN MISSING')
			return false
		var first = get_numerical_value(backward_connections[current_logical_node[0]][0],backward_connections)
		var second = get_numerical_value(backward_connections[current_logical_node[0]][1],backward_connections)
		return current_logical_node[0].apply_conditional(first,second)
	if current_logical_node[0].value == 'DoubleBool':
		return current_logical_node[0].apply_operation(\
			get_bool_value(backward_connections[current_logical_node[0]][0],backward_connections),\
			get_bool_value(backward_connections[current_logical_node[0]][1],backward_connections))
	if current_logical_node[0].value == 'log':
		var parent_val = get_bool_value(backward_connections[current_logical_node[0]][0],backward_connections)
		var log_str = current_logical_node[0].log(parent_val)
		log_graph_output(log_str)
		return parent_val

func evaluate_conditional(current_branch_node, backward_connections):
	# a branch node has two backward connections
	for node in backward_connections[current_branch_node]:
		# node connected to pin 1 is bool
		if node[1] == 1:
			return get_bool_value(node,backward_connections)
	log_graph_output("BRANCH PIN MISSING")
	return false

func to_control_vector(previous_control, conditional_vector,check_against,node_forwards,backward_connections):
	# match pins on forwards nodes
	var control_vector = []
	var forwards_pin = node_forwards[1]
	if typeof(conditional_vector) != TYPE_ARRAY:
		for i in range(len(eval_ids)):
			if previous_control[i] == dead:
				control_vector.append(dead)
			else:
				control_vector.append(dead if conditional_vector!=check_against else forwards_pin)
	else:
		for i in range(len(conditional_vector)):
			var val = conditional_vector[i]
			if previous_control[i] == dead:
				control_vector.append(dead)
			else:
				control_vector.append(dead if val!=check_against else forwards_pin)
	return control_vector

func evaluate_node(current_control_node,control_termination,input_control_vector,forward_connections,backward_connections):
	
	if current_control_node == control_termination:
		# register the input control vector for evaluation
		output_arrays.append(input_control_vector)
	elif current_control_node.value == 'Branch':
		var conditional_vector = evaluate_conditional(current_control_node,backward_connections)
		if len(forward_connections[current_control_node]) != 2:
			return 'invalid_branch'
		var first_output_control_vector = to_control_vector(input_control_vector,conditional_vector,true,forward_connections[current_control_node][0],backward_connections)
		var second_output_control_vector = to_control_vector(input_control_vector,conditional_vector,false,forward_connections[current_control_node][1],backward_connections)
		var error_first  = evaluate_node(forward_connections[current_control_node][0][0],control_termination,first_output_control_vector,forward_connections,backward_connections)
		var error_second = evaluate_node(forward_connections[current_control_node][1][0],control_termination,second_output_control_vector,forward_connections,backward_connections)
		if error_first == 'invalid_branch' or error_second == 'invalid_branch':
			return 'invalid_branch'
	else:
		var error = evaluate_node(forward_connections[current_control_node][0][0],control_termination,input_control_vector,forward_connections,backward_connections)
		return error

func sort_backwards_connections(first, second):
	return first[1] < second[1]
	
func sort_forwards_connections(first, second):
	return first[2] < second[2]

func reduce_output():
	var final_output = []
	for i in range(len(eval_ids)):
		for output_index in range(len(output_arrays)):
			if output_arrays[output_index][i] != dead:
				final_output.append(output_arrays[output_index][i])
	#print('reduced output: ', final_output)
	return final_output

func evaluate_graph(graph_input):
	#print("\n\n\nEVAL GRAPH")
	graph_output = ''
	
	# built in function to read the graph
	var connection_list = get_connection_list()
	#print(connection_list)
	var forward_connections = {}
	var backward_connections = {}
	var control_origin = null
	var control_termination = null
	# process the read graph
	for i in range(0,connection_list.size()):
		#input
		var connection_input= get_node(connection_list[i].from)
		var input_pin = connection_list[i].from_port
		var input_value = connection_input.value
		
		#output
		var connection_output = get_node(connection_list[i].to)
		var output_pin = connection_list[i].to_port
		var output_value = connection_output.value
		
		#where does graph start/end?
		if connection_input.value == "ControlOrigin":
			control_origin = connection_input
		if connection_output.value == "action":
			control_termination = connection_output
		
		#build a dictionary of all forward connections
		if connection_input in forward_connections:
			forward_connections[connection_input].append([connection_output,output_pin,input_pin])
		else:
			forward_connections[connection_input] = [[connection_output,output_pin,input_pin]]
		
		#build a dictionary of all backward connections
		if connection_output in backward_connections:
			backward_connections[connection_output].append([connection_input,output_pin,input_pin])
		else:
			backward_connections[connection_output] = [[connection_input,output_pin,input_pin]]
	
	# this is where control originates from
	var current_control_node = control_origin
	var selected_pin = null
	
	var control_input = []
	
	# we're not connected with output?
	if not control_origin in forward_connections:
		for i in range(len(eval_ids)):
			control_input.append(2)
			
		return [control_input]
	
#	for id in ids:
#		control_input.append(forward_connections[control_origin][0][1])
		
	for connections in backward_connections:
		backward_connections[connections].sort_custom(self, "sort_backwards_connections")
		
#	print('pre sort: ')
	for connections in forward_connections:
#		print('connections: ', forward_connections[connections])
		forward_connections[connections].sort_custom(self, "sort_forwards_connections")
#	print('post sort: ')
#	for connections in forward_connections:
#		print('post connections: ', forward_connections[connections])
	
	
	var error = evaluate_node(control_origin,control_termination,control_input,forward_connections,backward_connections)
	
	
	var output_phi_theta = get_numerical_value([control_termination,3], backward_connections)
		
	if error == 'invalid_branch':
		var dead_output = []
		for i in range(len(output_phis)):
			dead_output.append(8) #dead
		return [dead_output,output_phis,output_thetas]
	
	get_node("../Output").text = graph_output
	return [reduce_output()]


