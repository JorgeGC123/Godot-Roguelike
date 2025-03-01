extends SceneTree

func _init():
	print("=== INICIANDO TEST RUNNER ===")
	var args = OS.get_cmdline_args()
	var test_name = ""
	
	# Procesar argumentos
	for arg in args:
		if arg.begins_with("--test="):
			test_name = arg.replace("--test=", "")
	
	# Cargar y ejecutar los tests
	if test_name != "":
		run_specific_test(test_name)
	else:
		run_all_tests()
	
	# Finalizar la ejecución
	print("=== TESTS COMPLETADOS ===")
	quit()

func run_all_tests():
	print("Ejecutando todos los tests...")
	
	var tests = {
		"inventory_model": load("res://Tests/TestInventoryModel.gd"),
		"inventory_manager": load("res://Tests/TestInventoryManager.gd"),
		"item_factory": load("res://Tests/TestItemFactory.gd"),
		"inventory_ui": load("res://Tests/TestInventoryUI.gd"),
		"saved_data_cycle": load("res://Tests/TestSavedDataCycle.gd"),
		"simple": load("res://Tests/SimpleTest.gd")
	}
	
	var passed = 0
	var failed = 0
	
	for test_name in tests:
		var result = run_test_suite(test_name, tests[test_name])
		passed += result.passed
		failed += result.failed
	
	print("\n=== RESUMEN ===")
	print("Tests exitosos: %d" % passed)
	print("Tests fallidos: %d" % failed)
	print("Total: %d" % (passed + failed))

func run_specific_test(test_name):
	print("Ejecutando test: %s" % test_name)
	
	var test_path = "res://Tests/Test" + test_name.capitalize() + ".gd"
	if ResourceLoader.exists(test_path):
		var test_script = load(test_path)
		run_test_suite(test_name, test_script)
	else:
		print("ERROR: Test '%s' no encontrado en %s" % [test_name, test_path])

func run_test_suite(suite_name, script):
	print("\n=== SUITE: %s ===" % suite_name)
	
	var test_instance = script.new()
	var test_methods = []
	
	# Encontrar todos los métodos de test
	for method in test_instance.get_method_list():
		if method.name.begins_with("test_"):
			test_methods.append(method.name)
	
	var results = {
		"passed": 0,
		"failed": 0
	}
	
	# Ejecutar cada método de test
	for method in test_methods:
		print("\nTest: %s" % method)
		
		# Si el test tiene setup, ejecutarlo
		var test_data = null
		if test_instance.has_method("setup"):
			test_data = test_instance.setup()
		
		# Ejecutar el test
		var result = test_instance.call(method)
		
		# Si el test tiene teardown, ejecutarlo
		if test_instance.has_method("teardown") and test_data != null:
			test_instance.teardown(test_data)
		
		# Evaluar resultado
		if result == true:
			print("  ✓ PASS")
			results.passed += 1
		else:
			print("  ✗ FAIL")
			results.failed += 1
	
	print("\nResultados %s: %d pasados, %d fallidos" % [
		suite_name, 
		results.passed, 
		results.failed
	])
	
	return results
