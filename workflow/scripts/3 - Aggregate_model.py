import json
import xgboost as xgb
import glob

# Function to extracts number of trees and parallel trees from an XGBoost model JSON.
def get_tree_nums(xgb_model_json):
    model_data = json.loads(xgb_model_json)
    num_trees = int(model_data["learner"]["gradient_booster"]["model"]["gbtree_model_param"]["num_trees"])
    num_parallel_tree = int(model_data["learner"]["gradient_booster"]["model"]["gbtree_model_param"]["num_parallel_tree"])
    return num_trees, num_parallel_tree

# Function to aggregate multiple XGBoost models using tree-based bagging and saves the final global model.
def aggregate_xgb_models(local_model_files, global_model_path_json, global_model_path):
    
    # Use the first local model as base global model
    with open(local_model_files[0], "r") as f:
        global_model_json = f.read()
    global_model_data = json.loads(global_model_json)

    # Extract initial number of trees
    global_tree_num, _ = get_tree_nums(global_model_json)
    iteration_indptr = global_model_data["learner"]["gradient_booster"]["model"].get("iteration_indptr", [0])

    # Iterate through remaining models and merge local model trees
    for i, model_file in enumerate(local_model_files[1:], start=2):
        with open(model_file, "r") as f:
            curr_model_json = f.read()
        curr_model_data = json.loads(curr_model_json)

        curr_num_trees , curr_parallel_tree = get_tree_nums(curr_model_json)

        # Update number of trees in the global model
        global_model_data["learner"]["gradient_booster"]["model"]["gbtree_model_param"]["num_trees"] = str(global_tree_num + curr_num_trees)

        # Merge trees
        curr_trees = curr_model_data["learner"]["gradient_booster"]["model"]["trees"]

        for t in range(curr_num_trees):
            curr_trees[t]["id"] = global_tree_num + t  

            print(f"Appending tree {t + 1} from local model {i}")
            print(curr_trees[t])

            # Append new trees safely
            global_model_data["learner"]["gradient_booster"]["model"]["trees"].append(curr_trees[t])

        # Update global tree count
        global_tree_num += curr_num_trees
        iteration_indptr.append(iteration_indptr[-1] + curr_num_trees)
        
    global_model_data["learner"]["gradient_booster"]["model"]["tree_info"] = [0] * len(global_model_data["learner"]["gradient_booster"]["model"]["trees"])
    # Ensure num_trees is correctly set
    global_model_data["learner"]["gradient_booster"]["model"]["gbtree_model_param"]["num_trees"] = str(len(global_model_data["learner"]["gradient_booster"]["model"]["trees"]))


# Ensure iteration_indptr is updated correctly
    global_model_data["learner"]["gradient_booster"]["model"]["iteration_indptr"] = list(range(
    len(global_model_data["learner"]["gradient_booster"]["model"]["trees"]) + 1
))

    # Save the final aggregated model in JSON format
    with open(global_model_path_json, "w") as f:
        json.dump(global_model_data, f)

    print(f"Global model saved as JSON: {global_model_path_json}")

    global_model = xgb.Booster(model_file=global_model_path_json)
    global_model.save_model(global_model_path)

    print(f"Global model saved as BST: {global_model_path}")

    return global_model


local_model_dir = "Local_model/Local_model_json/"

local_model_files = glob.glob(local_model_dir + "XGB_train_set_*.json") 


#### Run aggregation function and save the global model 
global_model_path_json = "Global_model/global_xgb_model.json"
global_model_path = "Global_model/global_xgb_model.model"

global_model = aggregate_xgb_models(local_model_files, global_model_path_json, global_model_path)

params_dict = json.loads(global_model.save_config())


# Extract key parameters
num_trees = params_dict["learner"]["gradient_booster"]["gbtree_model_param"]["num_trees"]
num_parallel_tree = params_dict["learner"]["gradient_booster"]["gbtree_model_param"]["num_parallel_tree"]
max_depth = params_dict["learner"]["gradient_booster"]["tree_train_param"]["max_depth"]
eta = params_dict["learner"]["gradient_booster"]["tree_train_param"]["eta"]
colsample_bytree = params_dict["learner"]["gradient_booster"]["tree_train_param"]["colsample_bytree"]
subsample = params_dict["learner"]["gradient_booster"]["tree_train_param"]["subsample"]
lambda_reg = params_dict["learner"]["gradient_booster"]["tree_train_param"]["lambda"]
alpha_reg = params_dict["learner"]["gradient_booster"]["tree_train_param"]["alpha"]
tree_method = params_dict["learner"]["gradient_booster"]["gbtree_train_param"]["tree_method"]
num_features = params_dict["learner"]["learner_model_param"]["num_feature"]


# Check model summary
print(f"Number of Trees: {num_trees}")
print(f"Parallel Trees per Boosting Round: {num_parallel_tree}")
print(f"Max Tree Depth: {max_depth}")
print(f"Learning Rate (eta): {eta}")
print(f"Features Used per Tree (colsample_bytree): {colsample_bytree}")
print(f"Data Used per Tree (subsample): {subsample}")
print(f"L2 Regularization (lambda): {lambda_reg}")
print(f"L1 Regularization (alpha): {alpha_reg}")
print(f"Tree Building Method: {tree_method}")
print(f"Number of Features in Dataset: {num_features}")


